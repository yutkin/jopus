from libcpp.vector cimport vector
from libcpp.string cimport string
from libcpp cimport bool


cdef extern from "jopus.h" namespace "jopus":
    struct OpusAudio:
        vector[float] samples
        unsigned int sizeInBytes
        float duration

        unsigned int inputSampleRate
        unsigned int preSkip
        int streamCount
        int channelCount
        int outputGain
        int mappingFamily
        string vendor

cdef extern from "jopus.h" namespace "jopus":
    OpusAudio openOpusFileByUrl(const string &url,
                                const string &proxy_host,
                                int proxy_port,
                                bool skip_ssl_cert_check) except +

    OpusAudio openOpusFile(const string &filepath) except +