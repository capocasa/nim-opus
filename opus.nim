
import opus/wrapper

const maxFrameSize = 5760
  ## Maximum buffer size per channel specified by OPUS
  ## 120ms maximum duration and 48000 maximum sample rate
  ## equals 0.12 * 48000 = 5760

type
  SampleRate* = enum
    sr8k = 8000
    sr12k = 12000
    sr16k = 16000
    sr24k = 24000
    sr48k = 48000
  Channels* = enum
    chMono = 1
    chStereo = 2
  DecoderObj* = object
    raw*: ptr cDecoder
    sampleRate*: SampleRate
    channels*: Channels
  Decoder* = ref DecoderObj
  SamplesObj* = object
    len*: int
      # total number of total samples
    data*: ptr UncheckedArray[int16]
      # array of samples
  Samples* = ref SamplesObj
  InitError* = object of Exception
  DecodeError* = object of ValueError

proc cleanup(decoder: Decoder) =
  decoder_destroy(decoder.raw)

proc newDecoder*(sampleRate: SampleRate, channels: Channels): Decoder =
  new(result, cleanup)
  result.sampleRate = sampleRate
  result.channels = channels
  var errorCode:cint
  result.raw = decoder_create(sampleRate.cint, channels.cint, errorCode.addr)
  if errorCode < 0:
    raise newException(InitError, $strerror(errorCode))

proc cleanup(samples: Samples) =
  deallocShared(samples.data)

template bytes*(samples: Samples): int =
  samples.len * sizeof(int16)

import random

proc decode*(decoder: Decoder, encoded: openArray[byte], errorCorrection: bool = false): Samples =
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
  #for i in 0..<result.len:
  #  result.data[i] = rand(int16) div 2

template decode*(decoder: Decoder, encoded: ptr UncheckedArray[byte], len: int, errorCorrection: bool = false): Samples =
  decode(decoder, toOpenArray(encoded, 0, len-1), errorCorrection)
