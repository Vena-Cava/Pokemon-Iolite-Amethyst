-------------------------------
 Modular Messages Plugin
 By Swdfm
 2024-11-02
-------------------------------
 Compatible with Essentials 21
-------------------------------
- If using, please give credit to Swdfm and Maruno
- If using the name tag/advanced portrait add on, please give credit to Mr.Gela, Golisopod User, mej71 and battlelegendblue
- If using an add on, please give credit to those listed on its page. The credits are also found at the bottom of this page
-------------------------------
 What does this Plugin do?
-------------------------------
- Splits up a method that was originally 278 lines long called pbMessageDisplay, which means that it a lot easier to edit text controls in the game, and means that you do not need to copy a huge portion of script across to your plugins should you wish to change text options!
- Adds a few extra controls that weren't on the vanilla scripts, some of which are very useful in my opinion, especially for translating games!
- Allows you to add and customise your own text controls a lot easier through handlers
- Adds a variation of Mr.Gela's name tags and advanced portraits that is compatible with this plugin and Essentials v21. It also makes it not clash with Carmaniac/NoNoNever's Speech Bubbles Script
-------------------------------
 How to install:
-------------------------------
1) You must first install Swdfm Utilities
  - You must use the 2024-11-02 version or later
  - If you have downloaded the plugin, it will likely come with it already attached
  - If you already have the Swdfm Utilities, ensure that you have the latest version
2) You must ensure that pbMessageDisplay is not used in any of your other plugins. If it is, let me (Swdfm) know which plugin it is, and I will try and make it compatible in a future update
3) Ensure that the Plugin is in the folder and loaded
-------------------------------
 Text Controls
-------------------------------
For those that don't know, putting \\YOUR_CONTROL in a string, or \YOUR_CONTROL in a "Show Text" section in RPG Maker has the potential to call a text control
For a full list and better explanation of the vanilla text controls, refer to this:
https://essentialsdocs.fandom.com/wiki/Messages
All of the vanilla controls should still work as intended in this plugin by default
-------------------------------
New/Updated Text Controls
-------------------------------
For the purposes of this document, "\" refers to "\" in "Show Text" and "\\" otherwise!
None of these are case sensitive
- \v[VARIABLE]
  - This is in the vanilla
  - But now VARIABLE can be referred to with a constant within your scripts
  - eg. \v[Settings::NO_MEGA_EVOLUTION] will return the result of variable 34
  - This can be useful if you don't want to keep tracking numbers!
- \sc[SCRIPT]
  - where SCRIPT refers to a script from the scripts section
  - It returns the value as a String.
  - You CAN NOT have in your script the characters "[" or "]", or else it will cause an error
- \GAME_DATA_CLASS[GAME_DATA_KEY]
  - eg. \species[pikachu] will return Pikachu
  - eg. \type[fire] will return Fire
  - Will work with almost anything in the form:
    - GameData::GAME_DATA_CLASS.get(GAME_DATA_KEY).name
  - For item plural names, use \itemplural[ITEM_CONST]
  - This will make it easier to run the game in foreign languages, and ensures consistency
-------------------------------
 Adding Your Own Text Controls
-------------------------------
This Plugin makes it a lot easier to add your own text controls, but here are some things to take on board while you do
1) Pick a control name
  - Make sure you pick a control name that is not already occupied
    - Ones that start with
      - b, c, e, f, g, l, n, r, v, or w
	  - should never really be used
  - Make sure you pick a control name that does not start with another control name that runs after that other name!
    - eg. two control names: swd and swdfm
      - If you insist on having them both, ensure swdfm is run first
  - For good practise, ensure it starts with a letter and is about 2-4 characters long
2) Add in the control handler
  - Ensure it is placed in an area that overrides this plugin
  - The best way to do that is to set this Plugin as a requirement for wherever you add the handler
  - Here is an example below
[code]
Modular_Messages::Controls.add("swdfm", {
  "both" => true,
  "before_appears" => proc { |hash, param|
    param = _INTL("epic") if param == ""
    hash["text"] = _INTL("Swdfm is {1}!: ", param) + hash["text"]
  }
})
[/code]
  - Near the end of the first line goes your control name

3) The hash keys are as follows:
  - "solo" => TRUE_OR_FALSE
    - Ensures the command is read only as \CONTROL_NAME and not \CONTROL_NAME[PARAM]
  - "both" => TRUE_OR_FALSE
    - Ensures the command is read both as \CONTROL_NAME and \CONTROL_NAME[PARAM]
	- If no [PARAM] is given, the PARAM is read as ""
  - Adding neither "solo" nor "both" means the script reads the control only as \CONTROL_NAME[PARAM]
  - "on_text_chunks" => PROC
    - Runs just after the text has been separated into text chunks and controls
	- hash["text_chunks"] refers to the chunks
	- hash["index"] refers to which text chunk is being iterated through
	  - Goes 0, 1, 2...
  - "before_appears" => PROC
    - Runs before the box itself appears
	- Useful to make any changes to the whole text/window
  - "during_loop"
    - Runs upon the messagebox getting to that control
	- Used for making changes midway through the text running
-------------------------------
 Add Ons
-------------------------------
For each add on, all the information should be on its respective Plugin Page!
- Name Tags and Advanced Portraits
  - Credit: Mr.Gela, Golisopod User, mej71 and battlelegendblue
- Easy Skip Messages (OFF by default!)
  - Credit: Amethyst & Kurotsune
-------------------------------
Thanks for using, and if you are having any problems with the plugin, please don't hesitate to contact me!
Thanks,
Swdfm