demo:
	cp -r example/* .

clean-demo: main.tex test.tex
	rm -f main.tex test.tex

clean-tex:
	rm main.*

clean:
	rm -rf .extex.build
	rm -f extex*.tex
	rm -rf extex-svg/ extex-pdf/