#!/bin/sh

TARGET_NAME="QuickDMG"
sitetear_path='/usr/local/bin/sitetear'
manual_folder="$HOME/Factories/Websites/scriptfactory/scriptfactory/ScriptGallery/TheOtherScripts/QuickDMG/manual"
#iconPath="$manual_folder/MergePDF16.png"

copyHelp() {
	manual_path=$1;
	helpdir=$2;
	mkdir -p "$helpdir"
	perl "$sitetear_path" "$manual_path" "$helpdir"
	open -a 'Help Indexer' "$helpdir"
	#cp "$iconPath" "$helpdir"
}

helpdir_en="English.lproj/${TARGET_NAME}Help"
helpdir_ja="Japanese.lproj/${TARGET_NAME}Help"

manual_page="index.html" 

copyHelp "$manual_folder/ja/$manual_page" "$helpdir_ja"
copyHelp "$manual_folder/en/$manual_page" "$helpdir_en"

