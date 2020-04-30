# ezTag: http://eztag.bioqrator.org
## Tagging biomedical concepts via interactive learning

ezTag is a web-based concept tagging tool that allows users to manually annotate text with biomedical concepts, use annotated data to train models, and use trained models to tag text automatically. Because ezTag is interactive, the automatically tagged text can then be refined manually to create new annotated data for training an improved model.

In ezTag, users can upload documents in [BioC](http://bioc.sourceforge.net/) format, including [PubMed](https://www.ncbi.nlm.nih.gov/pubmed) abstracts and [PubMed Central](https://www.ncbi.nlm.nih.gov/pmc) full-text articles. Biomedical concepts (biomedical named entities and their concept IDs) can then be annotated with one of several automated tools:

- State-of-the-art entity tagging tools such as [TaggerOne](https://www.ncbi.nlm.nih.gov/bionlp/Tools/taggerone), [GNormPlus](https://www.ncbi.nlm.nih.gov/bionlp/Tools/gnormplus) and [tmVar](https://www.ncbi.nlm.nih.gov/bionlp/Tools/tmvar)
- Our string match algorithm, using a user-provided lexicon

- Customized tagging models ([TaggerOne](https://www.ncbi.nlm.nih.gov/bionlp/Tools/taggerone)) trained on a set of annotated documents (i.e. a collection).

NOTE: This repository contains the source code of the ezTag web interface (concept tagging tools excluded).


## How to install ezTag into PC
You should first set up some software packages (e.g. Ruby, Rails, MySQL, etc) to run ezTag on your computer.
(Some features such as TaggerOne integration are not available for local installations)

For PC, follow the instructions in https://medium.com/ruby-on-rails-web-application-development/how-to-install-rubyonrails-on-windows-7-8-10-complete-tutorial-2017-fc95720ee059.

For Mac, please follow https://gorails.com/setup/osx/10.14-mojave.

For Linux, please follow https://gorails.com/setup/ubuntu/19.10.

You may also need to install Node.js.

After the basic setup,

1) git clone https://github.com/ncbi-nlp/ezTag.git
2) Configure config/database.yml and config/secrets.yml (run "rake secret" to get a key). You can find sample files in the config directory.
3) bundle install
4) rake db:create
5) rake db:migrate

To run ezTag,
1) rails s
2) Enter localhost:3000 on a web browser (we suggest Chrome)

