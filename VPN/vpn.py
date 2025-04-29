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


def display_menu_with_search(stdscr, title, options, selected_idx=0, search_query=""):
    """Display a menu with the given title and options with search functionality."""
    stdscr.clear()
    h, w = stdscr.getmaxyx()

    # Print title
    title = f"===== {title} ====="
    stdscr.addstr(1, (w - len(title)) // 2, title)

    # Display search box if a search is active
    if search_query:
        search_text = f"Search: {search_query}"
        stdscr.addstr(2, 2, search_text)

        # Filter options based on search query
        filtered_options = [
            opt for opt in options if search_query.lower() in opt.lower()
        ]
    else:
        filtered_options = options
        stdscr.addstr(2, 2, "Press '/' to search")

    # Adjust selected index if it's out of bounds after filtering
    if filtered_options and selected_idx >= len(filtered_options):
        selected_idx = len(filtered_options) - 1

    # Print options
    start_y = 4
    if filtered_options:
        for i, option in enumerate(filtered_options):
            x = (w - len(option)) // 2
            y = start_y + i

            if i == selected_idx:
                stdscr.attron(curses.A_REVERSE)
                stdscr.addstr(y, x, option)
                stdscr.attroff(curses.A_REVERSE)
            else:
                stdscr.addstr(y, x, option)
    else:
        no_match = "No matches found"
        stdscr.addstr(start_y, (w - len(no_match)) // 2, no_match)

    # Print instructions
    instructions = "Use J/K or UP/DOWN keys to navigate, ENTER to select, Q to quit, / to search, ESC to clear search"
    # Make sure it fits on screen
    if len(instructions) > w:
        instructions = (
            "J/K to navigate, ENTER to select, Q to quit, / search, ESC clear"
        )
    stdscr.addstr(h - 2, (w - len(instructions)) // 2, instructions)

    stdscr.refresh()

    return filtered_options


def get_search_input(stdscr, current_search=""):
    """Get search input from user."""
    curses.curs_set(1)
    h, w = stdscr.getmaxyx()
    search_win = stdscr.derwin(1, w - 10, 2, 10)  # Create a subwindow for search input
    search_win.clear()
    curses.echo()  # Enable echo mode to see what's being typed

    search_query = current_search
    search_win.addstr(0, 0, search_query)
    stdscr.refresh()
    search_win.refresh()

    while True:
        try:
            key = search_win.getch()

            if key == 27:  # Escape
                search_query = ""
                break
            elif key == 10:  # Enter
                break
            elif key == curses.KEY_BACKSPACE or key == 127:  # Backspace
                if search_query:
                    search_query = search_query[:-1]
                    search_win.clear()
                    search_win.addstr(0, 0, search_query)
            elif key in range(32, 127):  # Printable characters
                search_query += chr(key)
                search_win.addstr(0, 0, search_query)

            search_win.refresh()
        except curses.error:
            # Handle window size errors
            pass

    curses.noecho()  # Disable echo mode
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


def main(stdscr):
    # Set up curses
    curses.curs_set(0)  # Show cursor for search input
    curses.start_color()
    curses.use_default_colors()
    stdscr.clear()
    stdscr.keypad(True)  # Enable special keys

    # Parse config files
    configs = parse_config_files()

    # Show country selection menu
    countries = list(configs.keys())
    country_idx = 0
    country_search = ""

    while True:
        filtered_countries = display_menu_with_search(
            stdscr, "Select a Country", countries, country_idx, country_search
        )

        # Get user input
        key = stdscr.getch()

        if key == ord("/"):
            # Enter search mode
            country_search = get_search_input(stdscr, country_search)
            country_idx = 0  # Reset selection index after search
        elif key == 27:  # Escape key
            country_search = ""  # Clear search
        elif (key == ord("k") or key == curses.KEY_UP) and country_idx > 0:
            country_idx -= 1
        elif (
            (key == ord("j") or key == curses.KEY_DOWN)
            and filtered_countries
            and country_idx < len(filtered_countries) - 1
        ):
            country_idx += 1
        elif key == 10 and filtered_countries:  # Enter key and we have filtered results
            # Selected a country
            selected_country = filtered_countries[country_idx]
            cities = list(configs[selected_country].keys())
            city_idx = 0
            city_search = ""

            # If there's only one city, skip directly to protocol selection
            if len(cities) == 1:
                selected_city = cities[0]
                available_protocols = list(
                    configs[selected_country][selected_city].keys()
                )
                protocol_idx = 0
                protocol_search = ""

                # Protocol selection loop
                while True:
                    filtered_protocols = display_menu_with_search(
                        stdscr,
                        f"Select Protocol for {selected_city}, {selected_country}",
                        available_protocols,
                        protocol_idx,
                        protocol_search,
                    )

                    key = stdscr.getch()

                    if key == ord("/"):
                        protocol_search = get_search_input(stdscr, protocol_search)
                        protocol_idx = 0
                    elif key == 27:  # Escape key
                        protocol_search = ""  # Clear search
                    elif (key == ord("k") or key == curses.KEY_UP) and protocol_idx > 0:
                        protocol_idx -= 1
                    elif (
                        (key == ord("j") or key == curses.KEY_DOWN)
                        and filtered_protocols
                        and protocol_idx < len(filtered_protocols) - 1
                    ):
                        protocol_idx += 1
                    elif key == 10 and filtered_protocols:  # Enter key
                        selected_protocol = filtered_protocols[protocol_idx]
                        config_file = os.path.join(
                            DIR,
                            configs[selected_country][selected_city][selected_protocol],
                        )

                        # Exit curses mode
                        curses.endwin()

                        # Connect to VPN
                        connect_vpn(config_file, VPN_USERNAME, VPN_PASSWORD)

                        # Exit after connection attempt
                        return
                    elif key == ord("q") or key == ord("Q"):  # q or Q
                        # Go back to country selection
                        break
            else:
                # Multiple cities available, show city selection
                city_idx = 0
                city_search = ""

                # City selection loop
                while True:
                    filtered_cities = display_menu_with_search(
                        stdscr,
                        f"Select a City in {selected_country}",
                        cities,
                        city_idx,
                        city_search,
                    )

                    key = stdscr.getch()

                    if key == ord("/"):
                        city_search = get_search_input(stdscr, city_search)
                        city_idx = 0
                    elif key == 27:  # Escape key
                        city_search = ""  # Clear search
                    elif (key == ord("k") or key == curses.KEY_UP) and city_idx > 0:
                        city_idx -= 1
                    elif (
                        (key == ord("j") or key == curses.KEY_DOWN)
                        and filtered_cities
                        and city_idx < len(filtered_cities) - 1
                    ):
                        city_idx += 1
                    elif key == 10 and filtered_cities:  # Enter key
                        selected_city = filtered_cities[city_idx]
                        available_protocols = list(
                            configs[selected_country][selected_city].keys()
                        )
                        protocol_idx = 0
                        protocol_search = ""

                        # Protocol selection loop
                        while True:
                            filtered_protocols = display_menu_with_search(
                                stdscr,
                                f"Select Protocol for {selected_city}, {selected_country}",
                                available_protocols,
                                protocol_idx,
                                protocol_search,
                            )

                            key = stdscr.getch()

                            if key == ord("/"):
                                protocol_search = get_search_input(
                                    stdscr, protocol_search
                                )
                                protocol_idx = 0
                            elif key == 27:  # Escape key
                                protocol_search = ""  # Clear search
                            elif (
                                key == ord("k") or key == curses.KEY_UP
                            ) and protocol_idx > 0:
                                protocol_idx -= 1
                            elif (
                                (key == ord("j") or key == curses.KEY_DOWN)
                                and filtered_protocols
                                and protocol_idx < len(filtered_protocols) - 1
                            ):
                                protocol_idx += 1
                            elif key == 10 and filtered_protocols:  # Enter key
                                selected_protocol = filtered_protocols[protocol_idx]
                                config_file = os.path.join(
                                    DIR,
                                    configs[selected_country][selected_city][
                                        selected_protocol
                                    ],
                                )

                                # Exit curses mode
                                curses.endwin()

                                # Connect to VPN
                                connect_vpn(config_file, VPN_USERNAME, VPN_PASSWORD)

                                # Exit after connection attempt
                                return
                            elif key == ord("q") or key == ord("Q"):  # q or Q
                                # Go back to city selection
                                break
                    elif key == ord("q") or key == ord("Q"):  # q or Q
                        # Go back to country selection
                        break
        elif key == ord("q") or key == ord("Q"):  # q or Q
            break


if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except KeyboardInterrupt:
        print("\nExiting OpenVPN selector...")
