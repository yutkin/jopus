extern "C" {
#include <opusfile.h>
}

#include <algorithm>
#include <chrono>
#include <fstream>
#include <future>
#include <iostream>
#include <random>
#include <thread>
#include <unordered_map>
#include <vector>

namespace jopus {

struct OpusAudio {
  std::vector<float> samples;
  unsigned int sizeInBytes;
  float duration;

  unsigned int inputSampleRate;
  unsigned int preSkip;
  int streamCount;
  int channelCount;
  int outputGain;
  int mappingFamily;
  std::string vendor;
};

std::string ERR2STR(int err) {
  switch (err) {
    case OP_FALSE:
      return "A request did not succeed.";
    case OP_HOLE:
      return "There was a hole in the page sequence numbers (e.g., a page was "
             "corrupt or missing).";
    case OP_EREAD:
      return "An underlying read, seek, or tell operation failed when it "
             "should have succeeded.";
    case OP_EFAULT:
      return "An underlying read, seek, or tell operation failed when it "
             "should have succeeded.";
    case OP_EIMPL:
      return "The stream used a feature that is not implemented, such as an "
             "unsupported channel family.";
    case OP_EINVAL:
      return "One or more parameters to a function were invalid.";
    case OP_ENOTFORMAT:
      return "A purported Ogg Opus stream did not begin with an Ogg page, a "
             "purported header packet did not start with one of the required "
             "strings, 'OpusHead' or 'OpusTags', or a link in a chained file "
             "was encountered that did not contain any logical Opus streams.";
    case OP_EBADHEADER:
      return "A required header packet was not properly formatted, contained "
             "illegal values, or was missing altogether.";
    case OP_EVERSION:
      return "The ID header contained an unrecognized version number.";
    case OP_EBADPACKET:
      return "An audio packet failed to decode properly. This is usually "
             "caused by a multistream Ogg packet where the durations of the "
             "individual Opus packets contained in it are not all the same.";
    case OP_EBADLINK:
      return "We failed to find data we had seen before, or the bitstream "
             "structure was sufficiently malformed that seeking to the target "
             "destination was impossible";
    case OP_ENOSEEK:
      return "An operation that requires seeking was requested on an "
             "unseekable stream.";
    case OP_EBADTIMESTAMP:
      return "The first or last granule position of a link failed basic "
             "validity checks.";
    default:
      return "Unknown error: " + std::to_string(err);
  }
}

int __decode(OggOpusFile *of, OpusAudio *info) {
  ogg_int64_t n_samples = op_pcm_total(of, -1);

  if (n_samples == OP_EINVAL) {
    return OP_EINVAL;
  }

  const OpusHead *oh = op_head(of, -1);

  if (oh) {
    info->inputSampleRate = oh->input_sample_rate;
    info->preSkip = oh->pre_skip;
    info->channelCount = oh->channel_count;
    info->streamCount = oh->stream_count;
    info->outputGain = oh->output_gain;
    info->mappingFamily = oh->mapping_family;
  }

  const OpusTags *tags = op_tags(of, -1);
  if (tags) {
    info->vendor = tags->vendor;
  }

  info->duration = n_samples / 48000;
  info->sizeInBytes = op_raw_total(of, -1);

  info->samples.resize(n_samples);
  int buffSize = 120 * 48;
  int offset = 0;

  for (int ret = -1; ret != 0;) {
    buffSize = std::min(static_cast<int>(info->samples.size() - offset), buffSize);
    ret = op_read_float(of, info->samples.data() + offset, buffSize, NULL);
    if (ret == OP_HOLE) {
      std::cerr << "Hole detected. Corrupt file segment?" << std::endl;
      continue;
    }

    if (ret < 0) {
      return ret;
    }

    offset += ret;
  }

  info->samples.resize(offset);

  return 0;
}

OpusAudio openOpusFileByUrl(const std::string &url,
                            const std::string &proxy_host, int proxy_port,
                            bool skip_ssl_cert_check = false) {
  int err;
  const char *proxy_host_ =
      proxy_host.size() > 0 ? proxy_host.c_str() : nullptr;

  OggOpusFile *of = op_open_url(
      url.c_str(), &err, OP_HTTP_PROXY_HOST(proxy_host_),
      OP_HTTP_PROXY_PORT(proxy_port),
      OP_SSL_SKIP_CERTIFICATE_CHECK(int(skip_ssl_cert_check)), NULL);

  if (err != 0) {
    op_free(of);
    throw std::runtime_error("Could not open " + url + ": " + ERR2STR(err));
  }

  OpusAudio info;
  err = __decode(of, &info);

  op_free(of);

  if (err < 0) {
    throw std::runtime_error("Got error during decoding of " + url + ": " +
                             ERR2STR(err));
  }

  return info;
}

OpusAudio openOpusFile(const std::string &filepath) {
  int err;
  OggOpusFile *of = op_open_file(filepath.c_str(), &err);

  if (err != 0) {
    op_free(of);
    throw std::runtime_error("Could not open " + filepath + ": " +
                             ERR2STR(err));
  }

  OpusAudio info;
  err = __decode(of, &info);

  op_free(of);

  if (err < 0) {
    throw std::runtime_error("Got error during decoding of " + filepath + ": " +
                             ERR2STR(err));
  }

  return info;
}

}  // namespace jopus