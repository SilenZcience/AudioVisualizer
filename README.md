<div id="top"></div>

[![Linux][OS-Windows]][OS-Windows]

<br/>
<div align="center">
<h2 align="center">AudioVisualizer</h2>
   <p align="center">
      Simple AudioVisualizer made in AutoIt
      <br/>
      <a href="https://github.com/SilenZcience/AudioVisualizer/blob/main/src/AudioVisualizer.au3">
         <strong>Explore the code »</strong>
      </a>
      <br/>
      <br/>
      <a href="https://github.com/SilenZcience/AudioVisualizer/issues">Report Bug</a>
      ·
      <a href="https://github.com/SilenZcience/AudioVisualizer/issues">Request Feature</a>
   </p>
</div>


<details>
   <summary>Table of Contents</summary>
   <ol>
      <li>
         <a href="#about-the-project">About The Project</a>
         <ul>
            <li><a href="#made-with">Made With</a></li>
         </ul>
      </li>
      <li>
         <a href="#getting-started">Getting Started</a>
         <ul>
            <li><a href="#prerequisites">Prerequisites</a></li>
            <li><a href="#installation">Installation</a></li>
         </ul>
      </li>
      <li><a href="#usage">Usage</a>
         <ul>
         <li><a href="#examples">Examples</a></li>
         </ul>
      </li>
      <li><a href="#contact">Contact</a></li>
   </ol>
</details>

## About The Project

This project provides an AudioVisualizer with a variety of useful customizations, which you can apply to **audio-files** (.mp3,.ogg,.flac,.wav). It is also possible to apply this Visualizer to any **record-device** (e.g. microphones, virtual-cable) connected to your computer.

### Made With
[![AutoIt][MadeWith-AutoIt]](https://www.autoitscript.com/site)
[![2.4.5.0][BassUDF]](https://www.autoitscript.com/forum/files/file/493-basszip/)

<p align="right">(<a href="#top">back to top</a>)</p>

## Getting Started

### Prerequisites

No Prerequisites are neccessary; The executable `AudioVisualizer.exe` is sufficient.

> :warning: **You should never trust any executable file!**

> AutoIt executables are known for getting **misidentified** as a **virus**. In this case you will need to exclude the binary-file from any antivirus software installed. Feel free to read/compile the [AudioVisualizer.au3](src/AudioVisualizer.au3) yourself using the official [Aut2Exe Converter](https://www.autoitscript.com/site/autoit/downloads/).

### Installation

1. Clone the repository and move into the root\bin directory with:


```console
git clone git@github.com:SilenZcience/Cat_For_Windows.git
cd AudioVisualizer\bin
```
2. Run the `AudioVisualizer.exe` file:

```console
AudioVisualizer.exe
```

<p align="right">(<a href="#top">back to top</a>)</p>

## Usage

1) If you are playing your own music files, the following controls apply:

- Simply drag and drop any audiofiles, or folders containing them, into the application-window.

- Use `rightclick` to bring up a window, in which you can customize the visualizer.

- Use `spacebar` to play/pause the current music file.

- Use `right-arrow/left-arrow` to navigate between multiple audio files which you dragged into the application.

- Use `mousewheel` to increase/decrease the sound volume of the file currently playing.

2) If you want to use the Visualizer to display the sound of an recording-device:

- Press `rightclick` to bring up the customization-window.

- At the bottom left, press the button `MusicFile` or `SoundDevice` to click through your visualization options and select your recording-device.

- Press the `Apply change` button in the bottom right.

3) If you want to visualize the playback-sound of your computer:

- Install any virtual cable and connect it to your playback-device (this way your sound-output will be accessible as a record-device).

- See 2)

### Examples

![](img/control.png?raw=true "control.png")

![](img/example1.png?raw=true "example1.png")

![](img/example2.png?raw=true "example2.png")

![](img/example3.png?raw=true "example4.png")

![](img/example4.png?raw=true "example4.png")

<p align="right">(<a href="#top">back to top</a>)</p>

## Contact

> **SilenZcience** <br/>
[![GitHub-SilenZcience][GitHub-SilenZcience]](https://github.com/SilenZcience)

[OS-Windows]: https://img.shields.io/badge/os-windows-green

[MadeWith-AutoIt]: https://img.shields.io/badge/Made%20with-AutoIt-brightgreen
[BassUDF]: https://img.shields.io/badge/BassUDF-2.4.5.0-brightgreen

[Warning]: https://img.shields.io/badge/warning-orange?style=for-the-badge

[GitHub-SilenZcience]: https://img.shields.io/badge/GitHub-SilenZcience-orange
