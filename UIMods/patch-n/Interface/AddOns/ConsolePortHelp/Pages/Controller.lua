local _, Help = ...

Help:AddPage('Controller', nil, [[<HTML><BODY>
	<H1 align="center">
		Controller and Calibration
	</H1>
	<IMG src="Interface\Common\spacer" align="center" width="200" height="27"/>
	<p align="left">
		IMPORTANT: ConsolePort requires third-party software for keyboard and mouse emulation.<br/>
		Using third-party software is not prohibited as long as it doesn't automate your gameplay.
		<br/><br/>
		Calibration data is used to convert your controller's input into in-game bindings.<br/>
		|cFFFF6600If your controller does not work properly|r (buttons are incorrectly mapped, perform unexpected actions, etc.) then you'll need to recalibrate your controller.
		<br/><br/>
	</p>
	<H2 align="center">
		<a href="slash:/consoleport recalibrate">Click here to recalibrate your controller.</a>
	</H2><br/>
	<p align="left">
		<a href="page:WoWpadX">|cff69ccf0WoWpadX|r</a> is recommended for any type of controller on Windows.
		The controller layout you choose to use in-game is merely a graphical preference.
	</p>
	<IMG src="Interface\AddOns\ConsolePortHelp\Textures\CtrlSplash" align="center" width="768" height="384"/>
	<H2 align="center">
		<a href="slash:/consoleport type">Click here to choose controller layout.</a>
	</H2> 
</BODY></HTML>]])




Help:AddPage('Changing modifiers', 'Controller', [[<HTML><BODY>
	<H1 align="center">
		Changing modifiers
	</H1><br/>
	<p align="left">
		In order to change your modifiers, you'll need to swap them both in-game and in your input mapper. The in-game configuration is purely graphical, and has no effect on your bindings.
		<br/><br/>
		If you're using <a href="page:WoWpadX">|cff69ccf0WoWpadX|r</a>, enabling ConsolePort sync will export any changes in your WoWpadX profile automatically and prompt an interface reload to apply the new settings. Sync is recommended to ensure any changes you make match your in-game settings.
	</p><br/>
	<H1 align="center">
		Recommended settings
	</H1><br/>
	<H2 align="center">
		Best ergonomics and speed:
	</H2>
	<p align="center">
		Shift - |TInterface\AddOns\ConsolePort\Controllers\XBOX\Icons64\CP_TL1:24:24:0:-4|t   |TInterface\AddOns\ConsolePort\Controllers\XBOX\Icons64\CP_TL2:24:24:0:-4|t - Ctrl<br/>
		Shift - |TInterface\AddOns\ConsolePort\Controllers\PS4\Icons64\CP_TL1:24:24:0:-6|t   |TInterface\AddOns\ConsolePort\Controllers\PS4\Icons64\CP_TL2:24:24:0:-6|t - Ctrl
		<br/><br/>
	</p>
	<p align="left">
		Explanation: Keeping your modifiers on the left hand side makes it easier to combine multiple buttons on the shoulder and therefore results in slightly more agile gameplay.
		This also frees up the entire right hand side of your controller to individual bindings, instead of having to use multiple fingers on one hand to achieve the same result.
		In general, it's faster to do one thing with each hand than doing two things at once with one hand. 
	</p><br/>
	<H2 align="center">
		FFXIV style:
	</H2>
	<p align="center">
		Shift - |TInterface\AddOns\ConsolePort\Controllers\XBOX\Icons64\CP_TL2:24:24:0:-4|t   |TInterface\AddOns\ConsolePort\Controllers\XBOX\Icons64\CP_TR2:24:24:0:-4|t - Ctrl<br/>
		Shift - |TInterface\AddOns\ConsolePort\Controllers\PS4\Icons64\CP_TL2:24:24:0:-6|t   |TInterface\AddOns\ConsolePort\Controllers\PS4\Icons64\CP_TR2:24:24:0:-6|t - Ctrl
		<br/><br/>
	</p>
	<p align="left">
		Explanation: If you're coming from a background of playing FFXIV with a controller, you probably feel more at home using a split modifier setup.
		This setup is also more intuitive to beginners, but nonetheless contributes to somewhat slower gameplay. 
		If you're only using ConsolePort for casual endeavours, this might be a better choice for you.
	</p><br/>
	<H2 align="center">
		<a href="run:ConsolePortOldConfig:OpenCategory('Controls') ConsolePortOldConfigContainerControlsController:Click()">Click here to change your in-game modifiers.</a>
	</H2>
</BODY></HTML>]])




Help:AddPage('Custom profiles', 'Controller', [[<HTML><BODY>
	<H1 align="center">
		Creating custom profiles
	</H1><br/>
	<p align="left">
		• |cff69ccf0Shift|r and |cff69ccf0Ctrl|r need to be mapped to any of the buttons on the shoulder of the controller. You may choose which two of the four (six) buttons to use.
		<br/><br/>
		• Assign your sticks to |cff69ccf0WASD|r and mouse control. Assign the click action of each stick to the corresponding mouse button.
		<br/><br/>
		• Use regular keys for the rest of the buttons. It doesn’t matter which buttons you use, but it’s recommended to avoid |cff69ccf0Enter|r, |cff69ccf0Tab|r, |cff69ccf0Escape|r and keys that can conflict with the game client or your operating system in combination with |cff69ccf0Shift|r and |cff69ccf0Ctrl|r. The bindings these buttons represent on a normal keyboard and mouse setup can be bound via this config later on.
		<br/><br/>
		• Choosing buttons for your profile doesn’t affect your regular key bindings. The controller map is only used for calibration purposes and you may then configure your controller bindings separately in-game.
	</p>
	<IMG src="Interface\AddOns\ConsolePortHelp\Textures\CustomMap" align="center" width="768" height="384"/>
</BODY></HTML>]])




Help:AddPage('Steam controllers', 'Controller', [[<HTML><BODY>
	<H1 align="center">
		Steam controllers setup
	</H1><br/>
	<p align="left">
		Due to how non-steam games are added it may be difficult to find a proper configuration for this plugin.
Create a new configuration and set the keys to the following: 
	</p><br/>
	<IMG src="Interface\AddOns\ConsolePortHelp\Textures\Deck" align="center" width="550" height="270"/>
	<IMG src="Interface\AddOns\ConsolePortHelp\Textures\Steam" align="center" width="550" height="270"/>
</BODY></HTML>]])



Help:AddPage('Mac OS options', 'Controller', [[<HTML><BODY>
    <H1 align="center">
        Mac OS options
    </H1><br/>
    <p align="left">
        Running a 32-bit legacy game like 3.3.5a on modern macOS requires a compatibility layer, as macOS no longer supports 32-bit applications natively. 
        <br/><br/>
        The most efficient way to use ConsolePort and |cFFFF6600WoWpadX|r on Mac (both Intel and Apple Silicon/M-series) is through a Windows compatibility layer. This allows you to run the Windows version of the game and the mapper side-by-side.
    </p><br/>

    <H2 align="left">
        The Recommended Way: Wine / Whisky
    </H2>
    <p align="left">
        For both |cff69ccf0Apple Silicon (M1/M2/M3)|r and |cff69ccf0Intel Macs|r, using a Wine wrapper is the gold standard. It allows the Windows version of WoWpadX to communicate with the game.
        <br/><br/>
        1. Download |cFFFF6600Whisky|r (Open Source) or |cFFFF6600CrossOver|r.<br/>
        2. Create a new "Bottle" (Windows 10/11 64-bit).<br/>
        3. Place your WoW 3.3.5a folder inside the bottle's C: drive.<br/>
        4. Run |cFFFF6600WoWpadX.exe|r inside the same bottle as the game. This ensures the mapper can "see" the game window and the Pixel Bridge beacon.
        <br/><br/>
        |cffff269bNote:|r On Apple Silicon, macOS will automatically use Rosetta 2 to translate the instructions. Performance is usually near-native.
    </p><br/>

    <H2 align="left">
        Native Mapping (Alternative)
    </H2>
    <p align="left">
        If you are using a native Mac client (legacy systems only) or prefer native remappers, your options are:
        <br/><br/>
        |cff69ccf0• GameController Mapper:|r Available on the App Store. Modern, lightweight, and supports M-series chips natively. Highly recommended for simple remapping.<br/>
        |cff69ccf0• Steam:|r You can add WoW as a "Non-Steam Game." Steam's Input Mapper is powerful, but you must use |cFFFF6600Karabiner-Elements|r to fix modifier keys (Shift/Ctrl) as Steam often struggles to pass them to WoW on macOS.
    </p><br/>

    <H2 align="left">
        Legacy Options
    </H2>
    <p align="left">
        |cff69ccf0• Joystick Mapper:|r Good for older Intel Macs, but lacks the advanced features needed for smooth Pixel Bridge integration.<br/>
        |cff69ccf0• ControllerMate:|r Effectively discontinued. Does not support modern macOS versions or ARM architecture. Avoid on newer systems.
    </p>
</BODY></HTML>]]) 

Help:AddPage('Linux options', 'Controller', [[<HTML><BODY>
    <H1 align="center">
        Linux options
    </H1><br/>
    <p align="left">
        If you want to test ConsolePort with the new experimental feature called |cFFFF6600Pixel Bridge|r, It's recommended running the Windows version of |cFFFF6600WoWpadX|r directly through the same compatibility layer as your game.
    </p><br/>

    <H2 align="left">
        The Recommended Way: Steam / Proton
    </H2>
    <p align="left">
        If you use |cff69ccf0Steam|r or a |cff69ccf0Steam Deck|r, this is the easiest method:
        <br/><br/>
        1. Add |cFFFF6600Wow.exe|r as a Non-Steam Game.<br/>
        2. In the game's |cff69ccf0Properties > Compatibility|r, force a specific version (Proton 9.0 or GE-Proton is recommended).<br/>
        3. To run the mapper, use a launch command that opens both the game and |cFFFF6600WoWpadX.exe|r in the same "prefix". This ensures the mapper can see the game window.
    </p><br/>

    <H2 align="left">
        The Advanced Way: Lutris / Bottles
    </H2>
    <p align="left">
        If you prefer |cff69ccf0Lutris|r or |cff69ccf0Bottles|r:
        <br/><br/>
        1. Create a 64-bit Wine prefix (even for 32-bit WoW, as it provides better modern library support).<br/>
        2. Use the |cff69ccf0"Run EXE inside Prefix"|r feature to launch WoWpadX.exe.<br/>
        3. Ensure |cff69ccf0Gamescope|r is disabled if the mapper cannot find the window, as it can sometimes hide the Pixel Bridge beacon from external processes.
    </p><br/>

    <H2 align="left">
        ARM Linux (Raspberry Pi / Tablets / Phones)
    </H2>
    <p align="left">
        Running on ARM Linux (like a Raspberry Pi 5) is possible using |cFFFF6600Box86|r and |cFFFF6600Wine|r. 
        <br/><br/>
        You can also run on Android devices using Winlator or GameHub, though these platforms may introduce input latency and compatibility issues with WoWpadX.
    </p><br/>

    <H2 align="left">
        Native Alternative
    </H2>
    <p align="left">
		|cff69ccf0• Steam Input:|r An incredibly powerful tool built directly into the Steam client. It supports almost every controller and allows for advanced features like radial menus, action sets, and the latest 2026 circular response curves. It is the gold standard for handheld users.<br/><br/>
        |cff69ccf0• AntiMicroX:|r The modern standard for Linux controller mapping. It is highly powerful and supports Wayland. While it doesn't support the Pixel Bridge natively, it is one of the best native tool for general controller-to-keyboard mapping on Linux.
    </p>
</BODY></HTML>]])




-- WoWpadX description page
Help:AddPage('WoWpadX', 'Controller', [[<HTML><BODY>
    <IMG src="Interface\AddOns\ConsolePort\Textures\Logos\WP" align="center" width="128" height="128"/>
    <br/><br/><br/><br/><br/><br/>
    <H1 align="center">
        What is WoWpadX?
    </H1><br/>
    <p align="left">
        |cFFFF6600WoWpadX|r is a high-performance, native input mapper for ConsolePortLK. 
        Built with C++ and Qt6, it leverages the cutting-edge |cFFFF6600SDL3|r library with the goal to provide the lowest latency possible.
        <br/><br/>
        Its primary purpose is to convert modern controller input into standard keyboard and mouse events, enabling true console-style gameplay without the overhead of older .NET frameworks as used by it's predecessor WoWmapperX.
    </p>
    <br/>
    <H1 align="center">
        What do I need?
    </H1><br/>
    <p align="left">
        |cff69ccf0•|r A system running Windows 10, 11, or Linux (via Wine)<br/>
        |cff69ccf0•|r Microsoft Visual C++ Redistributable 2015-2022<br/>
        |cff69ccf0•|r Any controller supported by SDL3 (DualSense, Xbox, Switch, etc.)<br/>
        |cff69ccf0•|r World of Warcraft 3.3.5a or newer
    </p><br/>
    <H3 align="left">
			Unlike its predecessor, WoWpadX is a **standalone native application**. It does not require complex system-wide runtimes like .NET Framework, meaning it runs exactly as shipped without interfering with your Windows installation.    </H3><br/>
    <H2 align="center">
        <a href="website:https://github.com/leoaviana/WoWpadX/releases/latest">Click here to get a link to the latest release of WoWpadX.</a>
    </H2> 
</BODY></HTML>]])


Help:AddPage('Supported devices', 'WoWpadX', [[<HTML><BODY>
    <IMG src="Interface\AddOns\ConsolePort\Textures\Logos\WP" align="center" width="128" height="128"/>
    <br/><br/><br/><br/><br/><br/>
    <H1 align="center">
        Supported devices
    </H1><br/>
    <p align="left">
        WoWpadX features near-universal controller support thanks to the |cFFFF6600SDL3 Gamepad API|r. 
        Most devices are recognized automatically without any third-party software like X360CE or DS4Windows.
    </p><br/>
    <H2 align="left">
        Natively Supported:
    </H2>
    <p align="left">
        |cff69ccf0•|r |cFFFFFFFFPlayStation:|r DualSense, DualSense Edge, DualShock 4, and DS3<br/>
        |cff69ccf0•|r |cFFFFFFFFXbox:|r Series X|S, Xbox One, Elite Series 1 &amp; 2, and Xbox 360<br/>
        |cff69ccf0•|r |cFFFFFFFFNintendo:|r Switch Pro Controller and Joy-Cons<br/>
        |cff69ccf0•|r |cFFFFFFFFHandhelds:|r Steam Deck, ROG Ally, and Lenovo Legion Go<br/>
        |cff69ccf0•|r |cFFFFFFFFOther:|r 8BitDo, Logitech, Razer, and generic HID gamepads
    </p><br/>
    <H2 align="left">
        Advanced Features
    </H2>
    <p align="left">
        |cff69ccf0•|r |cFFFFFFFFLow Latency:|r Native C++ execution ensures your inputs reach the game instantly.<br/>
        |cff69ccf0•|r |cFFFFFFFFHotplugging:|r Connect or disconnect your controller while the game is running.<br/>
        |cff69ccf0•|r |cFFFFFFFFHaptic Sync:|r Integrated with the |cFFFF6600Pixel Bridge|r for health-based vibrations and movement awareness.
    </p><br/> 
    <p align="left">
        If your controller is not recognized, ensure it is in "X-Input" mode if it has a physical switch. Most modern Bluetooth controllers will "just work" the moment they are paired.
    </p>
</BODY></HTML>]])