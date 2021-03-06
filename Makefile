# `make test` genera un sitio de prueba en # http://test.endefensadelsl.org
# `make` o `make all` genera el sitio
#
# Toma todas los svg de las tapas y los convierte a tif
src_tapas        := $(wildcard assets/covers/*.svg)
src_single_tapas := $(wildcard assets/covers/single_*.svg)
tif_tapas        := $(patsubst %.svg,%.tif,$(src_tapas))
png_tapas        := $(patsubst %.svg,%.png,$(src_tapas))
pdf_tapas        := $(patsubst %.svg,%.pdf,$(src_single_tapas))

# Todos los pdfs originales
pdfs := $(filter-out $(wildcard tmp/pdf/*-binder.pdf), \
        $(filter-out $(wildcard tmp/pdf/*-imposed.pdf), \
        $(filter-out $(wildcard tmp/pdf/*-imposition.pdf), \
        $(filter-out $(wildcard tmp/pdf/*-con_tapa.pdf), \
        $(wildcard tmp/pdf/*.pdf)))))

pdfs_binder     := $(patsubst tmp/pdf/%.pdf, tmp/pdf/%-binder.pdf, $(pdfs))
pdfs_imposicion := $(patsubst tmp/pdf/%.pdf, tmp/pdf/%-imposition.pdf, $(pdfs))
pdfs_con_tapa   := $(patsubst %.pdf,%-con_tapa.pdf,$(pdfs))
ps              := $(patsubst %.pdf,%.ps,$(pdfs_imposicion))

copias    ?= 1
impresora ?= ImprentaEnDefensa

destination ?= ./site
site        ?= enlamarea.net
torrent     ?= enlamarea.torrent

# All es el primero para que sea la opción por defecto
all: tapas toggle-dest build binder imposicion covers empaquetar

toggle-test-dest:
	sed "s,^destination:.*,destination: $(destination)/test.$(site)," \
	    -i _config.yml

toggle-dest:
	sed "s,^destination:.*,destination: $(destination)/$(site)," \
	    -i _config.yml

build:
	bundle exec jekyll build

# Copia los PDFs binder y pisa los PDF de jekyll con los PDF con tapa
copiar-pdfs:
	cp -vt $(destination)/$(site)/pdf/ $(pdfs_binder)
	for i in $(pdfs_con_tapa); do \
		d="$${i##*/}" ; \
		d="$${d//-con_tapa}" ; \
		cp -vf "$$i" "$(destination)/$(site)/pdf/$$d" ; \
	done

seed:
	transmission-remote --add "$(destination)/$(site)/$(torrent)" \
	                    --download-dir "$(destination)" \
	                    --no-honor-session \
	                    --no-seedratio

release: 
	rsync -av --delete-after --progress \
	      $(destination)/$(site)/ \
	      $(site):$(destination)/$(site)/

test: toggle-test-dest build toggle-dest

clean:
	rm -rf tmp src/tmp _site

# Todas las tapas juntas
tapas: $(tif_tapas) $(png_tapas) $(pdf_tapas)

covers: $(pdfs_con_tapa)

# La encuadernación binder crea todas las páginas una detrás de otra
# porque se cortan y pegan individualmente (no se hace cuadernillo)
#
# +---+---+
# |   |   |
# | 1 | 1 |
# |   |   |
# +---+---+
# |   |   |
# | 1 | 1 |
# |   |   |
# +---+---+
binder: $(pdfs_binder)

# La imposición crea cuadernillos plegables por la mitad
#
# +----+----+
# |    |    |
# | 16 | 1  |
# |    |    |
# +----+----+
# |    |    |
# | 16 | 1  |
# |    |    |
# +----+----+
imposicion: $(pdfs_imposicion)

ps: $(ps)

imprimir:
	test -n "$(archivo)"
	for i in $(shell seq 1 $(copias)); do \
		lpr -o sides=two-sided-long-edge -P $(impresora) $(archivo) ;\
	done

empaquetar:
	tar cvzf $(destination)/$(site).tar.gz $(destination)/$(site)/

# Magia!
%.tif: %.svg
	convert -colorspace CMYK -density 300 '$<' '$@'

# Los sliders son de 730px
%.png: %.tif
	convert -resize 730x730\> '$<' '$@'

assets/covers/single_%.pdf: assets/covers/single_%.svg
	convert '$<' '$@'

tmp/pdf/%-con_tapa.pdf: tmp/pdf/%.pdf
	if test -f assets/covers/single_$*.pdf ; then \
		pdfunite assets/covers/single_$*.pdf '$<' '$@' ; \
	fi

tmp/pdf/%-binder.pdf: tmp/pdf/%-binder.latex
	pdflatex -output-directory tmp/pdf $<

tmp/pdf/%-binder.latex: tmp/pdf/%.pdf
	pages=$$(pdfinfo $< | grep Pages | cut -d: -f2 | tr -d " ") ;\
	printorder=$$(seq 1 $$pages | sed -e "p;p;p" | tr "\n" "," | sed -e "s/,$$//") ;\
	sed -e "s/@@pages@@/$$printorder/g" \
	    -e "s,@@document@@,$<,g" \
	    binder.latex >$@

tmp/pdf/%-imposition.pdf: tmp/pdf/%.pdf
	bundle exec ./bin/imposicion '$<'
