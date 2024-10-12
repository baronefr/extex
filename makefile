demo:
	cp -r example/* .

clean-demo: main.tex test.tex
	rm -f main.tex test.tex
	
clean:
	rm -rf .extex.build
	rm -rf extex-svg/ extex-pdf/