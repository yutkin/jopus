# cython: language_level=3
import numpy as np
cimport numpy as np

from jopus.jopus_decl cimport (
    OpusAudio as c_OpusAudio,
    openOpusFileByUrl as c_openOpusFileByUrl,
    openOpusFile as c_openOpusFile,
)

from libcpp.vector cimport vector

cdef extern from "<utility>" namespace "std" nogil:
  T move[T](T)

cdef class ArrayWrapper:
    cdef vector[float] vec
    cdef Py_ssize_t shape[1]
    cdef Py_ssize_t strides[1]

    cdef set_data(self, vector[float]& data):
       self.vec = move(data)

    def __getbuffer__(self, Py_buffer *buffer, int flags):
        cdef Py_ssize_t itemsize = sizeof(self.vec[0])

        self.shape[0] = self.vec.size()
        self.strides[0] = sizeof(float)
        buffer.buf = <char *>&(self.vec[0])
        buffer.format = 'f'
        buffer.internal = NULL
        buffer.itemsize = itemsize
        buffer.len = self.vec.size() * itemsize
        buffer.ndim = 1
        buffer.obj = self
        buffer.readonly = 0
        buffer.shape = self.shape
        buffer.strides = self.strides
        buffer.suboffsets = NULL

    def __releasebuffer__(self, Py_buffer *buffer):
        pass

class OpusAudio:

    def __init__(
            self,
            samples,
            input_sample_rate,
            output_gain,
            mapping_family,
            size_in_bytes,
            duration,
            num_streams,
            pre_skip,
            channel_count,
            vendor,
    ):
        self.samples = samples
        self.input_sample_rate = input_sample_rate
        self.output_gain = output_gain
        self.mapping_family = mapping_family
        self.size_in_bytes = size_in_bytes
        self.duration = duration
        self.num_streams = num_streams
        self.pre_skip = pre_skip
        self.channel_count = channel_count
        self.vendor = vendor

    def __repr__(self):
        return f"<OpusAudio({hex(id(self))}): " \
               f"sample_rate: {self.input_sample_rate}, " \
               f"duration: {self.duration}, " \
               f"streams: {self.num_streams}, " \
               f"channels: {self.channel_count}, " \
               f"size_in_bytes: {self.size_in_bytes}, " \
               f"vendor: {self.vendor}>"


def open_file(filepath) -> OpusAudio:
    cdef c_OpusAudio res = c_openOpusFile(filepath.encode())
    w = ArrayWrapper()
    w.set_data(res.samples)
    arr = np.asarray(w)
    arr.setflags(write=0)

    return OpusAudio(
        arr,
        res.inputSampleRate,
        res.outputGain,
        res.mappingFamily,
        res.sizeInBytes,
        res.duration,
        res.streamCount,
        res.preSkip,
        res.channelCount,
        res.vendor.decode(),
    )

def open_url(
        url: str,
        proxy_host:str = "",
        proxy_port: int =8080,
        skip_ssl_cert_check: bool = False,
) -> OpusAudio:
    cdef c_OpusAudio res = c_openOpusFileByUrl(
        url.encode(), proxy_host.encode(), proxy_port, skip_ssl_cert_check)

    w = ArrayWrapper()
    w.set_data(res.samples)
    arr = np.asarray(w)
    arr.setflags(write=0)

    return OpusAudio(
        arr,
        res.inputSampleRate,
        res.outputGain,
        res.mappingFamily,
        res.sizeInBytes,
        res.duration,
        res.streamCount,
        res.preSkip,
        res.channelCount,
        res.vendor.decode(),
    )
