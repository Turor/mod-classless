local _, Help = ...



Help:AddPage('Port Specifics', "welcome-page", [[<HTML><BODY>
<H1 align="center">Port Specifics</H1><br/>
<H2 align="left">A note for first-time users of this unofficial ConsolePort version for the legacy WOTLK client</H2>
<br/>
<p align="left">
    Some features do not work here due to the outdated addon engine of the client, and some will never work (at least not through standard means—see the custom library section). Certain features may have workarounds, and some of these are still listed on the Advanced page in case they are fixed, though they may be disabled or missing from the Settings page.
</p><br/>

<H1 align="center">What is not working?</H1><br/>
<p align="left">
    <a href="page:What is not working?">|cff69ccf0Click here to see which features cannot be implemented or are currently non-functional.|r</a>
</p><br/><br/>

<H1 align="center">Workarounds</H1><br/>
<p align="left">
    <a href="page:Workarounds and Tips">|cff69ccf0Click here to see features that may require user setup or tweaks to work properly and improve the experience.|r</a>
</p><br/>

<H2 align="left">Can missing functions be implemented to make certain features work?</H2><br/>
<p align="left">
    Possibly. With reverse engineering and memory editing, some functions (such as camera controls) can be added to the client. However, injecting libraries or modifying memory may trigger Warden and could result in a ban.
</p><br/>

<p align="left">
    If you are interested, there are two libraries that provide some of these missing functions for World of Warcraft:<br/><br/>
    • ConsoleXP — my project focused on controller helper functions and camera features (see also DynamicCamLK).<br/>
    • AwesomeWotlkLib — a library that ports modern APIs and fixes into 3.3.5a.<br/><br/>
    Both can extend functionality beyond what the legacy client supports by default.
</p><br/>
</BODY></HTML>]])

Help:AddPage('What is not working?', 'Port Specifics', [[<HTML><BODY>
<H1 align="center">What is not working?</H1>
<br/>
<p align="left">* Camera functions: Some camera related stuff won't work on WoTLK, that's because most camera features we're implemented in Legion and there is no known workaround for that.</p><br/>
<p align="left">* Highlight Next Target: Not possible because this is also a Legion feature</p><br/><br/>
<p align="left">Because both of these features are exclusive to the Legion (or newer) client, they cannot be implemented in the legacy WOTLK version without significant modifications. That's why ConsoleXP exists, see the <a href="page:Custom Libraries">|cff69ccf0Custom Libraries section for more information.|r</a></p><br/>
<p align="left"><a href="website:https://github.com/leoaviana/ConsolePortLK">|cff69ccf0If you see something else broken, you can report on the github page of this project, click here to obtain a link|r</a></p>
<br/>
</BODY></HTML>]])

Help:AddPage('Workarounds and Tips', 'Port Specifics', [[<HTML><BODY>
<H1 align="center">Workarounds and Tips</H1>
<br/>
<p align="left">*   EasyMotion (Unit hotkeys): You will need an unitframe addon to be able to use this feature, tested with ShadowedUnitFrames and XPerl Unitframes but hopefully will work with any unitframe addon available.<a href="page:Unit hotkeys">|cff69ccf0You can see what EasyMotion is by clicking here|r</a></p>

</BODY></HTML>]])

Help:AddPage('Custom Libraries', 'Port Specifics', [[<HTML><BODY>
    <H1 align="center">ConsoleXP</H1><br/>
    <p align="left">
        ConsoleXP is a modern enhancement for World of Warcraft 3.3.5a that brings quality-of-life features from retail WoW to the older client. It adds improvements such as dynamic camera, action targeting, and controller support.
    </p><br/>

    <H2 align="left">What It Does</H2>
    <p align="left">
        • Controller-friendly features like Action Targeting and Interact Button.<br/>
        • Customizable dynamic camera and targeting systems.<br/>
        • AddOn interface for configuration.<br/><br/>
        Learn more on the official project page: 
        <a href="website:https://github.com/leoaviana/ConsoleXP">|cff69ccf0ConsoleXP GitHub|r</a><br/><br/>
        For full control and customization over the dynamic camera mechanics, it is highly recommended to pair ConsoleXP with my port of <a href="website:https://github.com/leoaviana/DynamicCamLK">|cff69ccf0DynamicCamLK|r</a>.
    </p><br/>

    <H1 align="center">AwesomeWotlkLib</H1><br/>
    <p align="left">
        AwesomeWotlkLib is a powerful improvement library for WoW 3.3.5a. It ports modern APIs, fixes client bugs, and introduces new features such as:<br/><br/>
        • Smooth MSDF font rendering.<br/>
        • Clipboard fixes for non-English text.<br/>
        • Auto-login and camera FOV control.<br/>
        • Enhanced nameplate stacking and sorting.<br/>
        • New API functions, events, and CVars for developers.<br/><br/>
        You can use it alongside ConsoleXP.<br/><br/>
        Project page: 
        <a href="website:https://github.com/someweirdhuman/awesome_wotlk">|cff69ccf0AwesomeWotlkLib GitHub|r</a>
    </p><br/>

    <H2 align="left">Risks and Warnings</H2>
    <p align="left">
        Both libraries modifies the client by injecting a DLL. While safe for local play, servers with strict Warden or custom protections may detect and ban whoever is using it.<br/><br/>
        • Use at your own risk on custom servers.<br/>
        • Some servers may crash, block, or ban modified hooks.<br/>
        • Antivirus software may flag the patcher or injector as suspicious.
    </p><br/>

    <H2 align="left">Disclaimer</H2>
    <p align="left">
        ConsoleXP and AwesomeWotlkLib do not automate gameplay or provide unfair advantages. They are designed only to improve controls, APIs, and quality-of-life for players and developers.
    </p>
</BODY></HTML>]])