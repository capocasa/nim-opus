nim-opus
========

A nim wrapper for opus, the latest and greatest freely usable audio codec 

Portable and liberally licensed

Usage
-----

```nim

# Get data as an array-like structure from a demultiplexer
let encodedData = getMyEncodedData()

let decoder = newDecoder()
let samples = decoder.decode(encodedData)

for i in 0..<samples.len:
  echo $samples.data[i]
```

Documentation
-------------

Please see auto-generated documentation at https://capocasa.github.io/nim-opus/opus.html

Further information
-------------------

For a full usage example of the opus decoder, see the lov video player, https://github.com/capocasa/lov

Design and project status also applies to nim-opus as well.
