# ezTag: http://eztag.bioqrator.org
## Tagging biomedical concepts via interactive learning


ezTag is a web-based concept tagging tool that allows users to manually annotate text with biomedical concepts, use annotated data to train models, and use trained models to tag text automatically. Because ezTag is interactive, the automatically tagged text can then be refined manually to create new annotated data for training an improved model.


In ezTag, users can upload documents in [BioC](http://bioc.sourceforge.net/) format, including [PubMed](https://www.ncbi.nlm.nih.gov/pubmed) abstracts and [PubMed Central](https://www.ncbi.nlm.nih.gov/pmc) full-text articles. Biomedical concepts (biomedical named entities and their concept IDs) can then be annotated with one of several automated tools:

- State-of-the-art entity tagging tools such as [TaggerOne](https://www.ncbi.nlm.nih.gov/bionlp/Tools/taggerone), [GNormPlus](https://www.ncbi.nlm.nih.gov/bionlp/Tools/gnormplus) and [tmVar](https://www.ncbi.nlm.nih.gov/bionlp/Tools/tmvar)
- Our string match algorithm, using a user-provided lexicon

- Customized tagging models ([TaggerOne](https://www.ncbi.nlm.nih.gov/bionlp/Tools/taggerone)) trained on a set of annotated documents (i.e. a collection).

Basic workflow (without interactive learning):

![alt text](http://eztag.bioqrator.org/assets/overview-daa76057d297fe255a07a368d215cdf4547223b93dae32c61ea9e2327000b08e.jpg "ezTag basic workflow")

The blue boxes in the figure indicate the steps users should follow to navigate to the specified function.

