################################################################################
## @@ Generating .h files

## @ DOC_H_FILE
## The name of the header file to generate
DOC_H_FILE ?=

## @ DOC_H_DOCS
## The input DocBook files for generating the header file
DOC_H_DOCS ?=

$(DOC_H_FILE): $(DOC_H_DOCS);
	@rm -f $@; touch $@;
	echo 'const gchar** documentation_credits = {' >> $@
	for doc in $(DOC_H_DOCS); do \
	  xsltproc $(_credits) $$doc; \
	done | sort | uniq \
	  | awk 'BEGIN{s=""}{n=split($$0,w,"<");if(s!=""&&s!=substr(w[1],1,length(w[1])-1)){print s};if(n>1){print $$0;s=""}else{s=$$0}};END{if(s!=""){print s}}' \
	  | sed -e 's/\\/\\\\/' -e 's/"/\\"/' -e 's/\(.*\)/\t"\1",/' >> $@
	echo '	NULL' >> $@
	echo '};' >> $@
	echo >> $@
	for doc in $(DOC_H_DOCS); do \
	  docid=`echo $$doc  | sed -e 's/.*\/\([^/]*\)\.xml/\1/' \
	    | sed -e 's/[^a-zA-Z_]/_/g' | tr 'a-z' 'A-Z'`; \
	  ids=`xsltproc --xinclude $(_ids) $$doc`; \
	  for id in $$ids; do \
	    echo '#define HELP_'`echo $$docid`'_'`echo $$id \
	      | sed -e 's/[^a-zA-Z_]/_/g' | tr 'a-z' 'A-Z'`' "'$$id'"' >> $@; \
	  done; \
	  echo >> $@; \
	done;

.PHONY: dist-header
dist-header: $(DOC_H_FILE)
	$(INSTALL_DATA) $(DOC_H_FILE) $(distdir)/$(DOC_H_FILE)

doc-dist-hook: $(if $(DOC_H_FILE),dist-header)

.PHONY: chean-doc-header
_clean_doc_header = $(if $(DOC_H_FILE),clean-doc-header)
clean: $(_clean_doc_header)
distclean: $(_clean_doc_header)
mostlyclean: $(_clean_doc_header)
maintainer-clean: $(_clean_doc_header)
clean-doc-header:
	rm -f $(DOC_H_FILE)

all: $(DOC_H_FILE)


################################################################################
## @@ Public variables

## @ DOC_MODULE
## The name of the document being built
DOC_MODULE ?=

## @ DOC_ENTITIES
## Files included with a SYSTEM entity
DOC_ENTITIES ?=

## @ DOC_INCLUDES
## Files included with XInclude
DOC_INCLUDES ?=

## @ DOC_FORMATS
## The default formats to be built and installed
DOC_FORMATS ?= docbook
_DOC_REAL_FORMATS = $(if $(DOC_USER_FORMATS),$(DOC_USER_FORMATS),$(DOC_FORMATS))

## @ DOC_LINGUAS
## The languages this document is translated into
DOC_LINGUAS ?=

## @ RNGDOC_DIRS
## The directories containing RNG files to be documented with rngdoc
RNGDOC_DIRS ?=

## @ XSLDOC_DIRS
## The directories containing XSLT files to be documented with xsldoc
XSLDOC_DIRS ?=


################################################################################
## For bootstrapping gnome-doc-utils only

_xml2po ?= `which xml2po`

_db2omf ?= `pkg-config --variable db2omf gnome-doc-utils`
_rngdoc ?= `pkg-config --variable rngdoc gnome-doc-utils`
_xsldoc ?= `pkg-config --variable xsldoc gnome-doc-utils`
_credits ?= `pkg-congif --variable xmldir gnome-doc-utils`/xml/gnome/xslt/docbook/utils/credits.xsl
_ids ?= `pkg-congif --variable xmldir gnome-doc-utils`/xml/gnome/xslt/docbook/utils/ids.xsl


################################################################################
## @@ Rules for rngdoc

rngdoc_args =									\
	--stringparam rngdoc.id							\
	$(shell echo $(basename $(notdir $(1))) | sed -e 's/[^A-Za-z0-9_-]/_/g')\
	$(_rngdoc) $(filter %/$(basename $(notdir $(1))).rng,$(_RNGDOC_RNGS))

## @ _RNGDOC_RNGS
## The actual RNG files for which to generate documentation with rngdoc
_RNGDOC_RNGS = $(foreach dir,$(RNGDOC_DIRS),				\
	$(wildcard $(dir)/*.rng))

## @ _RNGDOC_C_DOCS
## The generated rngdoc documentation in the C locale
_RNGDOC_C_DOCS = $(foreach rng,$(_RNGDOC_RNGS),				\
	C/$(basename $(notdir $(rng))).xml)

# FIXME: Fix the dependancies
$(_RNGDOC_C_DOCS) : $(_RNGDOC_RNGS)
	xsltproc -o $@ $(call rngdoc_args,$@,$<)

.PHONY: rngdoc
rngdoc: $(_RNGDOC_C_DOCS)


################################################################################
## @@ Rules for xsldoc

xsldoc_args =									\
	--stringparam xsldoc.id							\
	$(shell echo $(basename $(notdir $(1))) | sed -e 's/[^A-Za-z0-9_-]/_/g')\
	$(_xsldoc) $(filter %/$(basename $(notdir $(1))).xsl,$(_XSLDOC_XSLS))

## @ _XSLDOC_XSLS
## The actual XSLT files for which to generate documentation with xsldoc
_XSLDOC_XSLS = $(foreach dir,$(XSLDOC_DIRS),				\
	$(wildcard $(dir)/*.xsl))

## @ _XSLDOC_C_DOCS
## The generated xsldoc documentation in the C locale
_XSLDOC_C_DOCS = $(foreach xsl,$(_XSLDOC_XSLS),				\
	C/$(basename $(notdir $(xsl))).xml)

# FIXME: Fix the dependancies
$(_XSLDOC_C_DOCS) : $(_XSLDOC_XSLS)
	xsltproc -o $@ $(call xsldoc_args,$@,$<)

.PHONY: xsldoc
xsldoc: $(_XSLDOC_C_DOCS)


################################################################################
## @@ OMF Files

db2omf_args =									\
	--stringparam db2omf.basename $(DOC_MODULE)				\
	--stringparam db2omf.format $(3)					\
	--stringparam db2omf.dtd						\
	$(shell grep -h PUBLIC $(2) | head -n 1 | sed -e 's/.*PUBLIC //')	\
	--stringparam db2omf.lang $(dir $(2))					\
	--stringparam db2omf.omf_dir $(OMF_DIR)					\
	--stringparam db2omf.help_dir $(HELP_DIR)				\
	--stringparam db2omf.omf_in `pwd`/$(_DOC_OMF_IN)			\
	$(_db2omf) $(2)

## @ _DOC_OMF_IN
## The OMF input file
_DOC_OMF_IN = $(if $(DOC_MODULE),$(wildcard $(DOC_MODULE).omf.in))

## @ _DOC_OMF_DB
## The OMF files for DocBook output
_DOC_OMF_DB = $(if $(_DOC_OMF_IN),						\
	$(foreach lc,C $(DOC_LINGUAS),$(DOC_MODULE)-$(lc).omf))

$(_DOC_OMF_DB) : $(_DOC_OMF_IN)
$(_DOC_OMF_DB) : $(DOC_MODULE)-%.omf : %/$(DOC_MODULE).xml
	xsltproc -o $@ $(call db2omf_args,$@,$<,'docbook')

## @ _DOC_OMF_HTML
## The OMF files for HTML output
_DOC_OMF_HTML = $(if $(_DOC_OMF_IN),						\
	$(foreach lc,C $(DOC_LINGUAS),$(DOC_MODULE)-html-$(lc).omf))

$(_DOC_OMF_HTML) : $(_DOC_OMF_IN)
$(_DOC_OMF_HTML) : $(DOC_MODULE)-html-%.omf : %/$(DOC_MODULE).xml
	xsltproc -o $@ $(call db2omf_args,$@,$<,'html')

## @ _DOC_OMF_ALL
## All OMF output files to be built
# FIXME
_DOC_OMF_ALL =									\
	$(if $(findstring docbook,$(_DOC_REAL_FORMATS)),$(_DOC_OMF_DB))		\
	$(if $(findstring html,$(_DOC_REAL_FORMATS)),$(_DOC_OMF_HTML))

.PHONY: omf
omf: $(_DOC_OMF_ALL)


################################################################################
## @@ Desktop Entry Files

## @ _DOC_DSK_IN
## The desktop entry input file
_DOC_DSK_IN = $(if $(DOC_MODULE),$(wildcard $(DOC_MODULE).desktop.in))

## @ _DOC_DSK_DB
## The desktop entry files for DocBook output
_DOC_DSK_DB = $(if $(_DOC_DSK_IN),						\
	$(foreach lc,C $(DOC_LINGUAS),$(DOC_MODULE).db.$(lc).desktop))

# FIXME
$(_DOC_DSK_DB) : $(_DOC_DSK_IN)
$(_DOC_DSK_DB) : $(DOC_MODULE).db.%.desktop : %/$(DOC_MODULE).xml
	cp $(_DOC_DSK_IN) $@

## @ _DOC_DSK_HTML
## The desktop entry files for HTML output
_DOC_DSK_HTML = $(if $(_DOC_DSK_IN),						\
	$(foreach lc,C $(DOC_LINGUAS),$(DOC_MODULE).html.$(lc).desktop))

$(_DOC_DSK_HTML) : $(_DOC_DSK_IN)
$(_DOC_DSK_HTML) : $(DOC_MODULE).html.%.desktop : %/$(DOC_MODULE).xml
	cp $(_DOC_DSK_IN) $@

## @ _DOC_DSK_ALL
## All desktop entry output files to be built
# FIXME
_DOC_DSK_ALL =									\
	$(if $(findstring docbook,$(_DOC_REAL_FORMATS)),$(_DOC_DSK_DB))		\
	$(if $(findstring html,$(_DOC_REAL_FORMATS)),$(_DOC_DSK_HTML))

.PHONY: dsk
dsk: $(_DOC_DSK_ALL)


################################################################################
## @@ C Locale Documents

## @ _DOC_C_MODULE
## The top-level documentation file in the C locale
_DOC_C_MODULE = $(if $(DOC_MODULE),C/$(DOC_MODULE).xml)

## @ _DOC_C_ENTITIES
## Files included with a SYSTEM entity in the C locale
_DOC_C_ENTITIES = $(foreach ent,$(DOC_ENTITIES),C/$(ent))

## @ _DOC_C_XINCLUDES
## Files included with XInclude entity in the C locale
_DOC_C_INCLUDES = $(foreach inc,$(DOC_INCLUDES),C/$(inc))

## @ _DOC_C_DOCS
## All documentation files in the C locale
_DOC_C_DOCS =								\
	$(_DOC_C_ENTITIES)	$(_DOC_C_INCLUDES)			\
	$(_RNGDOC_C_DOCS)	$(_XSLDOC_C_DOCS)			\
	$(_DOC_C_MODULE)

## @ _DOC_C_DOCS_NOENT
## All documentation files in the C locale
_DOC_C_DOCS_NOENT =							\
	$(_DOC_C_MODULE)	$(_DOC_C_INCLUDES)			\
	$(_RNGDOC_C_DOCS)	$(_XSLDOC_C_DOCS)

## @ _DOC_C_HTML
## All HTML documentation in the C locale
# FIXME: probably have to shell escape to determine the file names
_DOC_C_HTML = $(patsubst %.xml,%.html,$(_DOC_C_MODULE))


################################################################################
## @@ Other Locale Documentation

## @ _DOC_POFILES
## The .po files used for translating the document
_DOC_POFILES = $(if $(DOC_MODULE),					\
	$(foreach lc,$(DOC_LINGUAS),$(lc)/$(lc).po))

.PHONY: po
po: $(_DOC_POFILES)

## @ _DOC_LC_MODULES
## The top-level documentation file in all other locales
_DOC_LC_MODULES = $(if $(DOC_MODULE),					\
	$(foreach lc,$(DOC_LINGUAS),$(lc)/$(DOC_MODULE).xml))

## @ _DOC_LC_XINCLUDES
## Files included with XInclude entity in all other locales
_DOC_LC_INCLUDES =							\
	$(foreach lc,$(DOC_LINGUAS),$(foreach inc,$(_DOC_C_INCLUDES),	\
		$(lc)/$(notdir $(inc)) ))

## @ _RNGDOC_LC_DOCS
## The generated rngdoc documentation in all other locales
_RNGDOC_LC_DOCS =							\
	$(foreach lc,$(DOC_LINGUAS),$(foreach doc,$(_RNGDOC_C_DOCS),	\
		$(lc)/$(notdir $(doc)) ))

## @ _XSLDOC_LC_DOCS
## The generated xsldoc documentation in all other locales
_XSLDOC_LC_DOCS =							\
	$(foreach lc,$(DOC_LINGUAS),$(foreach doc,$(_XSLDOC_C_DOCS),	\
		$(lc)/$(notdir $(doc)) ))

## @ _DOC_LC_HTML
## All HTML documentation in all other locales
# FIXME: same as above
_DOC_LC_HTML =								\
	$(foreach lc,$(DOC_LINGUAS),$(foreach doc,$(_DOC_C_HTML),	\
		$(lc)/$(notdir $(doc)) ))

## @ _DOC_LC_DOCS
## All documentation files in all other locales
_DOC_LC_DOCS =								\
	$(_DOC_LC_MODULES)	$(_DOC_LC_INCLUDES)			\
	$(_RNGDOC_LC_DOCS)	$(_XSLDOC_LC_DOCS)			\
	$(if $(findstring html,$(_DOC_REAL_FORMATS)),$(_DOC_LC_HTML))

$(_DOC_POFILES): $(_DOC_C_DOCS)
	if ! test -d $(dir $@); then mkdir $(dir $@); fi
	if ! test -f $@; then \
	  (cd $(dir $@) && $(_xml2po) -e $(_DOC_C_DOCS_NOENT:%=../%) > $(notdir $@)); \
	else \
	  (cd $(dir $@) && $(_xml2po) -e -u $(basename $(notdir $@)) $(_DOC_C_DOCS_NOENT:%=../%)); \
	fi

# FIXME: fix the dependancy
# FIXME: hook xml2po up
$(_DOC_LC_DOCS) : $(_DOC_POFILES)
$(_DOC_LC_DOCS) : $(_DOC_C_DOCS)
	cp C/$(notdir $@) $@


################################################################################
## @@ All Documentation

## @ _DOC_HTML_ALL
## All HTML documentation, only if it's built
_DOC_HTML_ALL = $(if $(findstring html,$(_DOC_REAL_FORMATS)), \
	$(_DOC_C_HTML) $(_DOC_LC_HTML))


################################################################################

.PHONY: clean-rngdoc clean-xsldoc clean-omf clean-dsk clean-lc

clean-rngdoc: ; rm -f $(_RNGDOC_C_DOCS) $(_RNGDOC_LC_DOCS)
clean-xsldoc: ; rm -f $(_XSLDOC_C_DOCS) $(_XSLDOC_LC_DOCS)
clean-omf: ; rm -f $(_DOC_OMF_DB) $(_DOC_OMF_HTML)
clean-dsk: ; rm -f $(_DOC_DSK_DB) $(_DOC_DSK_HTML)
clean-lc:  ; rm -f $(_DOC_LC_DOCS)

_clean_rngdoc = $(if $(RNGDOC_DIRS),clean-rngdoc)
_clean_xsldoc = $(if $(XSLDOC_DIRS),clean-xsldoc)
_clean_omf = $(if $(_DOC_OMF_IN),clean-omf)
_clean_dsk = $(if $(_DOC_DSK_IN),clean-dsk)
_clean_lc  = $(if $(DOC_LINGUAS),clean-lc)

clean:							\
	$(_clean_rngdoc)	$(_clean_xsldoc)	\
	$(_clean_omf)		$(_clean_dsk)		\
	$(_clean_lc)
mostlyclean:						\
	$(_clean_rngdoc)	$(_clean_xsldoc)	\
	$(_clean_omf)		$(_clean_dsk)		\
	$(_clean_lc)
maintainer-clean:					\
	$(_clean_rngdoc)	$(_clean_xsldoc)	\
	$(_clean_omf)		$(_clean_dsk)		\
	$(_clean_lc)

.PHONY: dist-docs dist-omf dist-dsk

dist-docs: $(_DOC_C_DOCS) $(_DOC_LC_DOCS) $(_DOC_POFILES)
	for lc in C $(DOC_LINGUAS); do \
	  $(mkinstalldirs) $(distdir)/$$lc; \
	done
	for doc in $(_DOC_C_DOCS) $(_DOC_LC_DOCS) $(_DOC_POFILES); do \
	  $(INSTALL_DATA) $$doc $(distdir)/$$doc; \
	done

dist-omf:
	$(INSTALL_DATA) $(_DOC_OMF_IN) $(distdir)/$(_DOC_OMF_IN)

dist-dsk:
	$(INSTALL_DATA) $(_DOC_DSK_IN) $(distdir)/$(_DOC_DSK_IN)

doc-dist-hook: 					\
	$(if $(DOC_MODULE),dist-docs)		\
	$(if $(_DOC_OMF_IN),dist-omf)		\
	$(if $(_DOC_DSK_IN),dist-dsk)

all:							\
	$(_DOC_C_DOCS)		$(_DOC_LC_DOCS)		\
	$(_DOC_OMF_ALL)		$(_DOC_DSK_ALL)		\
	$(_DOC_HTML_ALL)	$(_DOC_POFILES)

.PHONY: check-doc check-omf
check:							\
	$(if $(DOC_MODULE),check-doc)			\
	$(if $(_DOC_OMF_IN),check-omf)
check-doc: $(_DOC_C_DOCS) $(_DOC_LC_DOCS)
	for lc in C $(DOC_LINGUAS); do \
	  xmllint --noout --xinclude --postvalid $$lc/$(DOC_MODULE).xml; \
	done
check-omf: $(_DOC_OMF_ALL)
	for omf in $(_DOC_OMF_ALL); do \
	  xmllint --noout --dtdvalid 'http://scrollkeeper.sourceforge.net/dtds/scrollkeeper-omf-1.0/scrollkeeper-omf.dtd' $$omf; \
	done

.PHONY: install-doc install-html install-omf install-dsk
install-data-local:					\
	$(if $(DOC_MODULE),install-doc)			\
	$(if $(_DOC_HTML_ALL),install-html)		\
	$(if $(_DOC_OMF_IN),install-omf)		\
	$(if $(_DOC_DSK_IN),install-dsk)
install-doc:
	echo install-doc
install-html:
	echo install-html
install-omf:
	$(mkinstalldirs) $(DESTDIR)$(OMF_DIR)/$(DOC_MODULE)
	for omf in $(_DOC_OMF_ALL); do \
	  $(INSTALL_DATA) $$omf $(DESTDIR)$(OMF_DIR)/$(DOC_MODULE)/$$omf; \
	done
	-scrollkeeper-update -p $(localstate_dir)/scrollkeeper -o $(DESTDIR)$(OMF_DIR)/$(DOC_MODULE)
install-dsk:
	echo install-dsk

# uninstall
# installcheck
# installdirs
