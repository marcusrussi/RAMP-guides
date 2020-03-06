# Requirements:
# GNU Parallel
# GDrive (https://github.com/gdrive-org/gdrive)
# An OAuth client ID and secret (ask Marcus)

gdrive := ./gdrive/gdrive # Location of GDrive binary
gdrive_mime := application/vnd.oasis.opendocument.text
gdrive_opts := export --mime $(gdrive_mime) --force

egrep_pattern := "\'.*\.odt\'"

guides := $(shell cut -d, -f1 src/resource_guide_ids.csv)

.SECONDARY: # don't delete any "intermediate" files
.PHONY: guides guides_md guides_html

clean:
	@rm -rf out/

guides: guides_md guides_html guides_brokenlinks

guides_md:          $(patsubst %, out/md/%.md,      $(guides))
guides_html:        $(patsubst %, out/html/%.html,  $(guides))
guides_brokenlinks: $(patsubst %, out/broken/%.pdf, $(guides))

out/md/%.md: out/odt/%.odt
	@mkdir -p $(dir $@)
	pandoc -s -o $@ $^

out/html/%.html: out/odt/%.odt
	@mkdir -p $(dir $@)
	pandoc --metadata title=$(basename $@) -s -o $@ $^

out/odt/%.odt: out/guides_manifest.txt
	@touch -c $@

out/broken/%.pdf: out/html/%.html
	@mkdir -p $(dir $@)
	./src/blc.sh $^ $@

out/guides_manifest.txt: src/resource_guide_ids.csv
	@mkdir -p $(dir $@)/odt/
	parallel -j20 --csv -a $^ \
	  $(gdrive) $(gdrive_opts) {2} '|' \
	  egrep -om1 \'$(egrep_pattern)\' '|' \
	  xargs -n1 -I FILE mv FILE $(dir $@)/odt/{1}.odt
	@echo "Guides downloaded at: $(shell date)" > $@
