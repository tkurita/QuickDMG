property withResolveAlias : true

on run
	local thelist, theItem, nSelect
	set thelist to getSelection()
	set nSelect to length of thelist
	--log nSelect
	if nSelect is 0 then
		set thelist to missing value
	else if nSelect is 1 then
		set thelist to my checkIsSelectionMyself(item 1 of thelist)
	end if
	--return {"/Users/tkurita/Factories/Cocoa/QuickDMG/dmgtest" as Unicode text}
	return thelist
	--return missing value
end run

on resolveAlias(theItem)
	tell application "Finder"
		if withResolveAlias and (class of theItem is alias file) then
			try
				set theItem to original item of theItem
			end try
		end if
	end tell
	return theItem
end resolveAlias

on getSelection()
	tell application "Finder"
		set selectedList to selection
	end tell
	set thelist to {}
	repeat with theItem in selectedList
		set theItem to resolveAlias(theItem)
		if withResolveAlias then
			set theItem to POSIX path of (theItem as alias)
		else
			set theItem to POSIX path of (theItem as Unicode text)
		end if
		set end of thelist to theItem
	end repeat
	return thelist
end getSelection

on checkIsSelectionMyself(theItem)
	set myself to POSIX path of (path to current application)
	--display dialog "hello"
	(*
	tell  application "Finder"
		display dialog myself
	end tell
	*)
	--log myself
	if myself is theItem then
		return missing value
	else
		return {theItem}
	end if
end checkIsSelectionMyself
