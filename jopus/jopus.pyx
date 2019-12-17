# cython: language_level=3
import numpy as np

from jopus.jopus_decl cimport (
    OpusAudio as c_OpusAudio,
    openOpusFileByUrl as c_openOpusFileByUrl,
    openOpusFile as c_openOpusFile,
)

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


def open_file(filepath):
    cdef c_OpusAudio res = c_openOpusFile(filepath.encode())
    cdef float[:] mw = <float[:res.samples.size()]>res.samples.data()

    return OpusAudio(
        np.asarray(mw),
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
    cdef float[:] mw = <float[:res.samples.size()]>res.samples.data()

    return OpusAudio(
        np.asarray(mw),
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
