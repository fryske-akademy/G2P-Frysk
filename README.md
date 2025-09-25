# G2P-Frysk
Software for converting West Frisian text to phonetic IPA transcriptions.

Follow the instructions below to build the Docker image and launch the container.

### 1. Clone the Repo

```
git clone https://github.com/fryske-akademy/G2P-Frysk.git
cd G2P-Frysk
```

### 2. Build the Docker Image

```
docker build -t g2p-frysk .
```

### 3. Run the Container

```
docker run -p 3838:3838 g2p-frysk
```

### 4. View in Browser

Open:
http://localhost:3838

### Command line script

graph2phon is a command line script in R. View the header of the code for installation instructions and run:

```
Rscript graph2phon.R -h
```
for options.
