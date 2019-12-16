# Jopus
Simple, fast and efficient Python wrapper for libopusfile.

# Installation
## Requirements
### Ubuntu
`apt-get install libogg-dev libopus-dev libopusfile-dev`
### MacOS
`brew install opus opusfile libogg`

When requirements have been installed:
1. `git clone https://github.com/yutkin/jopus.git`
2. `cd jopus`
4. `pip install -r requirements.txt`
3. `pip install .`

# Usage example
```python
import jopus

# open file on file system
opus_file = jopus.open_file("/path_to_file.ogg")

# open file by URL
opus_file = jopus.open_url("https://hostname.com/opus_audio.ogg")

print(opus_file)
```
