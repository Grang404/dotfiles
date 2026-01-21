user_pref("widget.use-client-side-decorations", false);

// Disable telemetry
user_pref("toolkit.telemetry.archive.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("datareporting.policy.dataSubmissionEnabled", false);

// Disable experiments
user_pref("app.shield.optoutstudies.enabled", false);
user_pref("app.normandy.enabled", false);

// Disable WebRTC IP leak
user_pref("media.peerconnection.enabled", false);
user_pref("media.peerconnection.allow_old_setParameters", false);

// DNS over HTTPS (prevents DNS leaks)
user_pref("network.trr.mode", 0);

// Disable geolocation
user_pref("geo.enabled", false);

// Disable prefetching
user_pref("network.dns.disablePrefetch", true);
user_pref("network.prefetch-next", false);
user_pref("network.predictor.enabled", false);

// HTTPS-Only Mode
user_pref("dom.security.https_only_mode", true);

// Disable Pocket
user_pref("extensions.pocket.enabled", false);

user_pref("browser.contentblocking.category", "strict");

// Disable safe browsing (sends URLs to Google)
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("browser.safebrowsing.downloads.enabled", false);

// Resist fingerprinting
user_pref("privacy.resistFingerprinting", false);
