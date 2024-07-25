<h1 align="center">Quantifying Internal Phosphorus Loading in Large Lakes and Reservoirs across the United States</h1>

<p align="center">
  <strong>Smitom S. Borah<sup>1</sup>, Natalie G. Nelson<sup>2</sup>, Owen W. Duckworth<sup>3</sup></strong> , Daniel R. Obenour<sup>1</sup></strong>
</p>

<p align="center">
  <sup>1</sup>Department of Civil, Construction, and Environmental Engineering, North Carolina State University, Raleigh, 27606, USA<br>
  <sup>2</sup>Biological and Agricultural Engineering, North Carolina State University, Raleigh, NC, 27606, USA<br>
  <sup>3</sup>Department of Crop and Soil Sciences, North Carolina State University, Raleigh, 27606, USA
</p>


# Abstract

Internal phosphorus loading (IPL) can be a significant source of phosphorus (P) in freshwater systems. It is often cited for delayed water quality improvement following external load reductions. However, IPL flux estimates are missing for many lakes and reservoirs due to several challenges in large-scale measurement. Moreover, existing models have limited predictive skill or require covariates that may be unavailable at large spatial scales. In this study, we develop a predictive framework, combining random forest and linear mixed-effects regression, to predict summer IPL fluxes along with bottom-water temperature (BT) and waterbody total P (TP) concentration in nearly 6000 large lakes and reservoirs across the contiguous US (CONUS). We also demonstrate a novel approach to propagate the uncertainties across the predictive framework. Our results suggest 57% of waterbodies, largely in cropland areas, are likely to be eutrophic (TP > 35 𝜇g/L). Moreover, we estimate that summer IPL fluxes range from around 1-37 mg/m2/day across CONUS, with 31% of waterbodies having fluxes > 10 mg/m2/day. Summer IPL is likely to be greater than point source loadings in 43% of watersheds. Most of the uncertainty in our IPL estimates can be attributed to BT and TP inputs (estimated through random forest). Overall, our results reveal where IPL is likely to be a critical factor in watershed nutrient management.

## Table of Contents

- [About the Project](#about-the-project)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Contact](#contact)
- [Acknowledgements](#acknowledgements)

## About The Project

In this project, we provide the data and models developed as a part of our study to predict IPL in large lakes and reservoirs across the US. Additionally, codes for nationwide IPL, BT and TP predictions along with uncertainty quantification are provided. 

## Getting Started

The codes in this project are developed in R environment. To install and run R and RStudio on your computer, follow these steps:

### Installing R

1. **Download R:**
   - Visit the [CRAN website](https://cran.r-project.org/).
   - Select your operating system: Windows, macOS, or Linux.
   - Click on the appropriate link to download the R installer.

2. **Install R on Windows:**
   - Click on "Download R for Windows" and then on "base."
   - Download the latest version of R by clicking the link at the top of the new page.
   - Run the downloaded `.exe` file and follow the installation wizard steps.

3. **Install R on macOS:**
   - Click on "Download R for macOS."
   - Download the `.pkg` file for the latest version of R.
   - Run the `.pkg` file and follow the installation instructions.

### Installing RStudio

1. **Download RStudio:**
   - Go to the [RStudio website](https://www.rstudio.com/products/rstudio/download/).
   - Click on "DOWNLOAD" under the RStudio Desktop section.

2. **Install RStudio:**
   - Download the installer for your operating system (Windows `.exe` or macOS `.dmg`).
   - Run the installer and follow the installation prompts.

### Running R and RStudio

1. **Open RStudio:**
   - After installation, open RStudio from your Start menu (Windows) or Applications folder (macOS).

2. **Set Up RStudio:**
   - The RStudio interface consists of multiple panes: Source, Console, Environment, and Files/Plots/Packages/Help.
   - You can write R scripts in the Source pane and execute them in the Console.

3. **Install and Load Packages:**
   - Install packages using `install.packages("packageName")`.
   - Load packages using `library(packageName)`.

### Additional Resources

For detailed guides and additional resources on installing and using R and RStudio, you can refer to these tutorials:

- [Dataquest: Downloading and Installing R](https://www.dataquest.io/blog/installing-r-on-your-computer/)
- [Stats and R: How to install R and RStudio](https://statsandr.com/blog/how-to-install-r-and-rstudio/)
- [Hands-On Programming with R: Installing R and RStudio](https://rstudio-education.github.io/hopr/a-intro.html)

These guides provide comprehensive instructions and helpful visuals to ensure a smooth installation process.
### Prerequisites


