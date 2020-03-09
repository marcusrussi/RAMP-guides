# Requirements:
# - GNU Parallel
# - GDrive (https://github.com/gdrive-org/gdrive)
# - wkhtml2pdf
# - Python
# - pandoc
# - nodejs
# - broken-link-checker (https://github.com/stevenvachon/broken-link-checker)
#
# - An OAuth client ID and secret (ask Marcus)

# Location of GDrive binary. If this is already in your PATH, use
# $(which gdrive)
gdrive := ./gdrive/gdrive 

# MIME type of an ODT, which has to be specfied when exporting from Google Docs
gdrive_mime := application/vnd.oasis.opendocument.text

# --force means overwrite existing files
gdrive_opts := export --mime $(gdrive_mime) --force

# The output of 'gdrive' is such that we have to grep around to get the
# filename of the ODT we've just exported from Google Drive. This is the
# pattern that will match it.
egrep_pattern := "\'.*\.odt\'"

# 'src/resource_guide_ids.csv' is a k,v store where k=resource guide name, 
# v=gdrive ID corresponding to that resource guide. gdrive IDs are the hash
# in the URL of a Google Doc. Thus 'guides' is a list of resource guide names.
guides := $(shell cut -d, -f1 src/resource_guide_ids.csv)

.SECONDARY: # don't delete any "intermediate" files
.PHONY: guides guides_md guides_html guides_brokenlinks

clean:
	@rm -rf out/

# We grab the guides as ODTs and convert them to a few formats, as well as
# checking for broken links in any of them
guides: guides_md guides_html guides_brokenlinks

guides_md:          $(patsubst %, out/md/%.md,      $(guides)) # Markdown
guides_html:        $(patsubst %, out/html/%.html,  $(guides)) # HTML guides
guides_brokenlinks: $(patsubst %, out/broken/%.pdf, $(guides)) # Broken links

out/broken/%.pdf: out/html/%.html
	@mkdir -p $(dir $@)
	./src/blc.sh $^ $@

out/md/%.md: out/odt/%.odt
	@mkdir -p $(dir $@)
	# The -s flag means "standalone," see 'man pandoc' for details
	pandoc --from odt --to markdown --standalone --output $@ $^

out/html/%.html: out/odt/%.odt
	@mkdir -p $(dir $@)
	# You have to have a <title> so here is a crappy one
	pandoc --metadata "title:$(basename $@)" \
	  --from odt --to html --standalone --output $@ $^

out/odt/%.odt: out/guides_manifest.txt # A trick to get all the ODTs at once
	@touch -c $@

out/guides_manifest.txt: src/resource_guide_ids.csv
	@mkdir -p $(dir $@)/odt/
	# 20 jobs at once for more throughput.
	# --csv allows using a csv file where each column becomes {1}, {2}, etc
	# -a specifies the CSV file
	# 'egrep' filters output to get just the path to the ODT, -m means 
	#   only look at the first match
	# 'xargs' moves the ODT file into the out/odt/ directory
	parallel -j20 --csv -a $^ \
	  $(gdrive) $(gdrive_opts) {2} '|' \
	  egrep -om1 \'$(egrep_pattern)\' '|' \
	  xargs -n1 -I FILE mv FILE $(dir $@)/odt/{1}.odt
	@echo "Guides downloaded at: $(shell date)" > $@
