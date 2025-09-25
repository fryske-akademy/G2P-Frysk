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

<style>p { line-height: 1.5; } </style>

#### Command line script

graph2phon.R is an R command-line script. For installation instructions, check the header of the code. To see available options, run:

```
Rscript graph2phon.R -h
```
