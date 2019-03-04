PRODUCT := QuickDMG
SCHEME := "$(PRODUCT)"
# make instll SCHEME='QuickDMG sandbox'

install:
	xcodebuild -workspace '$(PRODUCT).xcworkspace' -scheme $(SCHEME) -configuration Release clean install DSTROOT=${HOME}

clean:
	xcodebuild -workspace '$(PRODUCT).xcworkspace' -scheme $(SCHEME) -configuration Release clean DSTROOT=${HOME}
