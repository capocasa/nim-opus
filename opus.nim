
## nim-opus is a high-level wrapper for the opus audio decoder.
## It uses nim features to achieve a concise, flexible interface
## and memory safety.
##
## If the low-level api is required to be accessed, opus/wrapper
## can be imported directly into a project.

import opus/wrapper

const maxFrameSize = 5760
  ## Maximum buffer size per channel specified by OPUS
  ## 120ms maximum duration and 48000 maximum sample rate
  ## equals 0.12 * 48000 = 5760

type
  SampleRate* = enum
    ## The possible sample rates for Opus encoding
    sr8k = 8000
    sr12k = 12000
    sr16k = 16000
    sr24k = 24000
    sr48k = 48000
  Channels* = enum
    ## The possible channel setups for Opus encoding
    ## This is the number of channels that the Opus encoder
    ## will use to optimize compression- more channels than
    ## this can be encoded seperately and then used together
    chMono = 1
    chStereo = 2
  DecoderObj* = object
    ## An object to refer to the low-level decoder and
    ## some select metadata
    raw*: ptr cDecoder
    sampleRate*: SampleRate
    channels*: Channels
  Decoder* = ref DecoderObj
    ## The high-level object to refer to the decoder. This
    ## object is memory safe, as all low-level memory allocations
    ## are freed when it goes out of scope
  SamplesObj* = object
    ## An object to hold an array of samples
    len*: int
      # total number of total samples
    data*: ptr UncheckedArray[int16]
      # array of samples
  Samples* = ref SamplesObj
    ## A simple container for an array full of samples. Sample
    ## values can be read or edited directly like this:
    ## 
    ## # get
    ## if mySampleObject.len >= 40:
    ##   echo $mySampleObject.data[40]
    ## 
    ## # set
    ## if mySampleObject.len >= 40:
    ##   mySampleObject.data[40] = -1
    ##
    ## This is unsafe, please do manual bounds checks
    ##
    ## This object should be converted to a data view  when they become available
    ##
  InitError* = object of Exception
    ## An error that occurs during decoder initialization
  DecodeError* = object of ValueError
    ## An error that occurrs during the decoding process

proc cleanup(decoder: Decoder) =
  decoder_destroy(decoder.raw)

proc newDecoder*(sampleRate: SampleRate = sr48000, channels: Channels = chStereo): Decoder =
  ## Initialize a new decoder for a given sample rate and channel setup.
  ## A decoder allocated this way will be memory safe.
  new(result, cleanup)
  result.sampleRate = sampleRate
  result.channels = channels
  var errorCode:cint
  result.raw = decoder_create(sampleRate.cint, channels.cint, errorCode.addr)
  if errorCode < 0:
    raise newException(InitError, $strerror(errorCode))

proc cleanup(samples: Samples) =
  ## The function that is called by a decoder ref's finalizer to remove its memory
  deallocShared(samples.data)


# The number of bytes contained by a Samples object
template bytes*(samples: Samples): int =
  samples.len * sizeof(int16)

proc decode*(decoder: Decoder, encoded: openArray[byte], errorCorrection: bool = false): Samples =
  ## Use a decoder to get samples from a packet of compressed data. The samples are PCM and can be
  ## played back using any audio interface, or converted to a different format.
  new(result, cleanup)
  result.data = cast[ptr UncheckedArray[int16]](allocShared0(maxFrameSize * decoder.channels.int))
  let frameSize = decode(
    decoder.raw,
    cast[ptr cuchar](encoded.unsafeAddr),
    encoded.len.cint,
    cast[ptr int16](result.data),
    maxFrameSize * decoder.channels.cint,
    errorCorrection.cint
  )
  if frameSize < 0:
    raise newException(DecodeError, $strerror(frameSize))
  result.len = frameSize * decoder.channels.int

template decode*(decoder: Decoder, encoded: ptr UncheckedArray[byte], len: int, errorCorrection: bool = false): Samples =
  ## Decode from data in an unchecked array with a length
  decode(decoder, toOpenArray(encoded, 0, len-1), errorCorrection)
