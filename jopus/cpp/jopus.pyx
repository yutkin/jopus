# cython: language_level=3

from typing import List

from jopus_decl cimport (
    OpusAudio as c_OpusAudio,
    openOpusFileByUrl as c_openOpusFileByUrl,
    openOpusFile as c_openOpusFile,
)

cdef class OpusAudio:
    __slots__ = ["info"]

    cdef c_OpusAudio info

    def __init__(self, const c_OpusAudio& info):
        self.info = info

    def __repr__(self):
        return f"<OpusAudioInfo({hex(id(self))}): " \
               f"sample_rate: {self.input_sample_rate}, " \
               f"duration: {self.duration}, " \
               f"streams: {self.num_streams}, " \
               f"channels: {self.channel_count}, " \
               f"size_in_bytes: {self.size_in_bytes}, " \
               f"vendor: {self.vendor}>"

    @property
    def output_gain(self) -> int:
        return self.info.outputGain

    @property
    def mapping_family(self) -> int:
        return self.info.mappingFamily

    @property
    def samples(self) -> List[float]:
        return self.info.samples

    @property
    def size_in_bytes(self) -> int:
        return self.info.sizeInBytes

    @property
    def duration(self) -> float:
        return self.info.duration

    @property
    def num_streams(self) -> int:
        return self.info.streamCount

    @property
    def input_sample_rate(self) -> int:
        return self.info.inputSampleRate

    @property
    def pre_skip(self) -> int:
        return self.info.preSkip

    @property
    def channel_count(self) -> int:
        return self.info.channelCount

    @property
    def vendor(self) -> str:
        return self.info.vendor.decode()

def open_url(
        url: str,
        proxy_host:str = "",
        proxy_port: int =8080,
        skip_ssl_cert_check: bool = False,
) -> OpusAudio:
    cdef c_OpusAudio res = c_openOpusFileByUrl(
        url.encode(), proxy_host.encode(), proxy_port, skip_ssl_cert_check)
    return OpusAudio(res)

def open_file(filepath: str) -> OpusAudio:
    cdef c_OpusAudio res = c_openOpusFile(filepath.encode())
    return OpusAudio(res)