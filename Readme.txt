This plugin will install the Pokemon World Tournament to your project.
This is an unofficial port of Luka SJ's original script for v17.2, made
by Vendily and DerxwnaKapsyla. Significant changes have been made to
bring the system in line in v20.1 standards, and other misc. tweaks
have been made to account for new and updated functions.

All of the files are in their relevant folders except for the two map 
files, "PWT Lobby" and "PWT Stadium". In order to use these correctly,
create two new maps in your project and take note of their ID Number.
Then, rename the relevant maps and rename them to match the two new
maps you just made.

For example, if your new maps are Map 45 and Map 70, you would
rename "PWT Lobby" and "PWT Stadium" to "Map045" and "Map070",
respectively. You will also want to also change the values of
PWT_MAP_DATA in "001_Settings.rb" to match the new map id,
x-position, and y-position of the spot you want the player
to be transfered to.

A guide on how to set up tournaments is provided in "001_Settings.rb",
and should cover most questions about how to set one up. Otherwise,
calling the tournament works the same as before. Just have an NPC
with a script command that says "startPWT", and everything should
be gravy!

Hopefully you all enjoy the plugin, we know this one has been something
people've wanted to see get ported forward for ages!

- DerxwnaKapsyla

PS: Vendily is fucking based for helping me get this all working
correctly. Mad props to them, I could not have done this without
their help!

#===========================================================================
#New and Changed Features with the port:
#- Now tracks the stats of Losses and Win Streaks
#- Will award BP based on a Win Streak
#- Now plays unique music in Round 3 and tournament victory
#  music.
#- Overhauled the Tournament definition structure
#  * Also allows for setting unique BP, rules, unlock conditions,
#    and banlist messages on a tournament by tournament basis.
#- Includes a graphic (from default Essentials) to serve as a
#  "placeholder" battle background.
#
#Removed Features with the port:
#- World Leaders has been removed as an individual bracket.
#===========================================================================


#===========================================================================
# Change Log
#===========================================================================
Version 1.0.4 - February 26th, 2023
* Release on PokéCommunity for Essentials 20

Version 1.0.5 - August 8th, 2024
* Tweak in wait method to support Essentials 21 waiting times