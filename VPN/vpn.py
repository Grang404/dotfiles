#!/usr/bin/env python3

import os
import subprocess
import curses

VPN_USERNAME = "i-BMP6-SDXZ-QL99"
VPN_PASSWORD = "ivpn"
DIR = "/home/alice/VPN/"


def parse_config_files(directory=DIR):
    """Parse OpenVPN config files and organize them by country, city, and protocol."""
    configs = {}

    for filename in os.listdir(directory):
        if filename.endswith(".ovpn") and not os.path.isdir(
            os.path.join(directory, filename)
        ):
            # Determine protocol (TCP or UDP)
            protocol = "TCP" if "-TCP" in filename else "UDP"

            # Remove protocol suffix for parsing
            base_name = filename.replace("-TCP.ovpn", "").replace(".ovpn", "")

            # Split the filename by hyphens and extract country and city
            parts = base_name.split("-")
            if len(parts) >= 2:
                country = parts[0].replace("_", " ")
                city = parts[1].replace("_", " ")

                # Initialize the country entry if it doesn't exist
                if country not in configs:
                    configs[country] = {}

                # Initialize the city entry if it doesn't exist
                if city not in configs[country]:
                    configs[country][city] = {}

                # Add the protocol and filename
                configs[country][city][protocol] = filename

    # Sort countries and cities
    sorted_configs = {}
    for country in sorted(configs.keys()):
        sorted_configs[country] = {
            city: configs[country][city] for city in sorted(configs[country].keys())
        }

    return sorted_configs


def safe_addstr(stdscr, y, x, text, attr=0):
    """Safely add string to screen, handling window boundaries."""
    try:
        h, w = stdscr.getmaxyx()
        if y >= 0 and y < h and x >= 0:
            # Truncate text if it would exceed window width
            max_len = w - x - 1
            if len(text) > max_len:
                text = text[:max_len-3] + "..."
            stdscr.addstr(y, x, text, attr)
    except curses.error:
        # Ignore errors from trying to write outside screen bounds
        pass


def display_menu_with_search(stdscr, title, options, selected_idx=0, search_query="", scroll_offset=0):
    """Display a menu with the given title and options with search functionality and scrolling."""
    stdscr.clear()
    h, w = stdscr.getmaxyx()
    
    # Minimum window size check
    if h < 10 or w < 30:
        safe_addstr(stdscr, h//2, max(0, (w-20)//2), "Window too small!", curses.A_BOLD)
        stdscr.refresh()
        return options, scroll_offset

    # Calculate available space for menu items
    header_lines = 4  # Title, search, blank line, and one more for padding
    footer_lines = 3  # Instructions and padding
    available_lines = max(1, h - header_lines - footer_lines)
    
    # Print title (truncate if necessary)
    title_text = f"===== {title} ====="
    if len(title_text) > w - 4:
        title_text = title[:w-12] + "... ====="
    safe_addstr(stdscr, 1, max(0, (w - len(title_text)) // 2), title_text, curses.A_BOLD)

    # Display search box or search prompt
    if search_query:
        search_text = f"Search: {search_query}"
        if len(search_text) > w - 4:
            search_text = f"Search: {search_query[:w-15]}..."
        safe_addstr(stdscr, 2, 2, search_text)
        
        # Filter options based on search query
        filtered_options = [
            opt for opt in options if search_query.lower() in opt.lower()
        ]
    else:
        filtered_options = options
        safe_addstr(stdscr, 2, 2, "Press '/' to search")

    # Adjust selected index and scroll offset if out of bounds after filtering
    if filtered_options:
        if selected_idx >= len(filtered_options):
            selected_idx = len(filtered_options) - 1
        
        # Adjust scroll offset to keep selected item visible
        if selected_idx < scroll_offset:
            scroll_offset = selected_idx
        elif selected_idx >= scroll_offset + available_lines:
            scroll_offset = selected_idx - available_lines + 1
        
        # Ensure scroll offset doesn't go negative or too high
        scroll_offset = max(0, min(scroll_offset, len(filtered_options) - available_lines))
    else:
        scroll_offset = 0

    # Print options with scrolling
    start_y = header_lines
    if filtered_options:
        visible_options = filtered_options[scroll_offset:scroll_offset + available_lines]
        
        for i, option in enumerate(visible_options):
            actual_idx = i + scroll_offset
            y = start_y + i
            
            # Center the option text, but truncate if too long
            display_text = option
            max_option_width = w - 4
            if len(display_text) > max_option_width:
                display_text = display_text[:max_option_width-3] + "..."
            
            x = max(2, (w - len(display_text)) // 2)
            
            if actual_idx == selected_idx:
                safe_addstr(stdscr, y, x, display_text, curses.A_REVERSE)
            else:
                safe_addstr(stdscr, y, x, display_text)
        
        # Show scroll indicators if needed
        if len(filtered_options) > available_lines:
            if scroll_offset > 0:
                safe_addstr(stdscr, start_y - 1, w - 5, "↑", curses.A_BOLD)
            if scroll_offset + available_lines < len(filtered_options):
                safe_addstr(stdscr, start_y + available_lines, w - 5, "↓", curses.A_BOLD)
            
            # Show position indicator
            pos_info = f"({selected_idx + 1}/{len(filtered_options)})"
            if len(pos_info) < w - 4:
                safe_addstr(stdscr, start_y + available_lines + 1, w - len(pos_info) - 2, pos_info)
    else:
        no_match = "No matches found"
        safe_addstr(stdscr, start_y, max(0, (w - len(no_match)) // 2), no_match)

    # Print instructions (adaptive based on window width)
    if w >= 80:
        instructions = "J/K or ↑/↓ to navigate, ENTER to select, Q to quit, / to search, ESC to clear search"
    elif w >= 60:
        instructions = "J/K or ↑/↓: navigate, ENTER: select, Q: quit, /: search, ESC: clear"
    else:
        instructions = "J/K:move ENTER:select Q:quit /:search"
    
    instruction_y = h - 2
    safe_addstr(stdscr, instruction_y, max(0, (w - len(instructions)) // 2), instructions)

    stdscr.refresh()
    return filtered_options, scroll_offset


def get_search_input(stdscr, current_search=""):
    """Get search input from user with improved window size handling."""
    h, w = stdscr.getmaxyx()
    
    # Check if window is too small for search input
    if w < 20:
        return current_search
    
    curses.curs_set(1)
    
    # Create search input area
    search_y = 2
    search_x = 10
    max_search_width = w - search_x - 2
    
    # Clear the search area
    try:
        stdscr.move(search_y, search_x)
        stdscr.clrtoeol()
    except curses.error:
        pass
    
    curses.echo()
    search_query = current_search

    # Display current search query
    display_query = search_query
    if len(display_query) > max_search_width:
        display_query = "..." + display_query[-(max_search_width-3):]
    
    safe_addstr(stdscr, search_y, search_x, display_query)
    stdscr.refresh()

    while True:
        try:
            key = stdscr.getch()

            if key == 27:  # Escape
                search_query = ""
                break
            elif key == 10:  # Enter
                break
            elif key == curses.KEY_BACKSPACE or key == 127:  # Backspace
                if search_query:
                    search_query = search_query[:-1]
            elif key in range(32, 127):  # Printable characters
                search_query += chr(key)
            
            # Update display
            stdscr.move(search_y, search_x)
            stdscr.clrtoeol()
            
            display_query = search_query
            if len(display_query) > max_search_width:
                display_query = "..." + display_query[-(max_search_width-3):]
            
            safe_addstr(stdscr, search_y, search_x, display_query)
            stdscr.refresh()
            
        except curses.error:
            # Handle any curses errors gracefully
            break

    curses.noecho()
    curses.curs_set(0)
    return search_query


def connect_vpn(config_file, username, password):
    """Connect to VPN using the selected config file and credentials."""
    print(f"Connecting to VPN using {config_file}...")

    # Create a temporary file for storing credentials
    cred_file = "/tmp/vpn_creds.txt"
    with open(cred_file, "w") as f:
        f.write(f"{username}\n{password}\n")

    try:
        # Set proper permissions for the credentials file
        os.chmod(cred_file, 0o600)

        # Run OpenVPN command
        cmd = [
            "sudo",
            "openvpn",
            "--config",
            config_file,
            "--auth-user-pass",
            cred_file,
        ]
        print(f"Executing: {' '.join(cmd)}")

        # Execute OpenVPN command
        subprocess.run(cmd)
    finally:
        # Clean up credentials file
        if os.path.exists(cred_file):
            os.remove(cred_file)


def handle_selection_menu(stdscr, title, options, configs=None, selected_country=None, selected_city=None):
    """Generic function to handle selection menus with improved navigation."""
    selected_idx = 0
    search_query = ""
    scroll_offset = 0
    
    while True:
        filtered_options, scroll_offset = display_menu_with_search(
            stdscr, title, options, selected_idx, search_query, scroll_offset
        )
        
        # Handle case where window is too small
        if not filtered_options and options:
            key = stdscr.getch()
            if key == ord("q") or key == ord("Q"):
                return None, None
            continue
        
        key = stdscr.getch()
        
        if key == ord("/"):
            # Enter search mode
            new_search = get_search_input(stdscr, search_query)
            if new_search != search_query:
                search_query = new_search
                selected_idx = 0
                scroll_offset = 0
        elif key == 27:  # Escape key
            if search_query:
                search_query = ""
                selected_idx = 0
                scroll_offset = 0
            else:
                return None, None  # Exit menu
        elif (key == ord("k") or key == curses.KEY_UP) and filtered_options and selected_idx > 0:
            selected_idx -= 1
        elif (key == ord("j") or key == curses.KEY_DOWN) and filtered_options and selected_idx < len(filtered_options) - 1:
            selected_idx += 1
        elif key == curses.KEY_PPAGE:  # Page Up
            selected_idx = max(0, selected_idx - 10)
        elif key == curses.KEY_NPAGE:  # Page Down
            if filtered_options:
                selected_idx = min(len(filtered_options) - 1, selected_idx + 10)
        elif key == curses.KEY_HOME:  # Home
            selected_idx = 0
        elif key == curses.KEY_END:  # End
            if filtered_options:
                selected_idx = len(filtered_options) - 1
        elif key == 10 and filtered_options:  # Enter key
            return filtered_options[selected_idx], selected_idx
        elif key == ord("q") or key == ord("Q"):
            return None, None


def main(stdscr):
    # Set up curses
    curses.curs_set(0)
    curses.start_color()
    curses.use_default_colors()
    stdscr.clear()
    stdscr.keypad(True)  # Enable special keys
    
    # Check minimum window size
    h, w = stdscr.getmaxyx()
    if h < 10 or w < 30:
        stdscr.clear()
        safe_addstr(stdscr, h//2, (w-30)//2, "Terminal too small! Need 30x10", curses.A_BOLD)
        safe_addstr(stdscr, h//2 + 1, (w-20)//2, "Press any key to exit")
        stdscr.refresh()
        stdscr.getch()
        return

    # Parse config files
    try:
        configs = parse_config_files()
    except Exception as e:
        stdscr.clear()
        error_msg = f"Error parsing configs: {str(e)}"
        safe_addstr(stdscr, h//2, max(0, (w-len(error_msg))//2), error_msg)
        safe_addstr(stdscr, h//2 + 1, (w-20)//2, "Press any key to exit")
        stdscr.refresh()
        stdscr.getch()
        return

    if not configs:
        stdscr.clear()
        safe_addstr(stdscr, h//2, (w-25)//2, "No VPN configs found!")
        safe_addstr(stdscr, h//2 + 1, (w-20)//2, "Press any key to exit")
        stdscr.refresh()
        stdscr.getch()
        return

    # Country selection
    countries = list(configs.keys())
    selected_country, _ = handle_selection_menu(stdscr, "Select a Country", countries)
    
    if not selected_country:
        return

    # City selection
    cities = list(configs[selected_country].keys())
    
    # If only one city, skip city selection
    if len(cities) == 1:
        selected_city = cities[0]
    else:
        selected_city, _ = handle_selection_menu(
            stdscr, f"Select a City in {selected_country}", cities
        )
        
        if not selected_city:
            return

    # Protocol selection
    available_protocols = list(configs[selected_country][selected_city].keys())
    selected_protocol, _ = handle_selection_menu(
        stdscr, f"Select Protocol for {selected_city}, {selected_country}", available_protocols
    )
    
    if not selected_protocol:
        return

    # Get config file path
    config_file = os.path.join(
        DIR, configs[selected_country][selected_city][selected_protocol]
    )

    # Exit curses mode
    curses.endwin()

    # Connect to VPN
    connect_vpn(config_file, VPN_USERNAME, VPN_PASSWORD)


if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except KeyboardInterrupt:
        print("\nExiting OpenVPN selector...")
    except Exception as e:
        print(f"Error: {e}")
        print("Make sure you have the required permissions and OpenVPN configs in the specified directory.")
