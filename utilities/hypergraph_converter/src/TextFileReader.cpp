
#ifndef _TEXTFILE_READER_CPP
#define _TEXTFILE_READER_CPP

// ### TextFileReader.cpp ###
//
// Copyright (C) 2004, Aleksandar Trifunovic, Imperial College London
//
// HISTORY:
//
// 01/12/2004: Last Modified
//
// ###

#include "TextFileReader.hpp"
#include <cstdlib>
#include <iostream>
#include <limits>

int TextFileReader::maxLength = 10000000;
int TextFileReader::maxPinsInChunk = 10000000;

TextFileReader::TextFileReader() {
  buffer.resize(maxLength);
  length = 0;
}

TextFileReader::~TextFileReader() {}

void TextFileReader::getLine(std::ifstream &input_stream) {
  // A hyperedge occupies one line, which may exceed the initial buffer size.
  // Reuse the string allocation and retain a mutable, NUL-terminated buffer for
  // the existing parsers (which modify comments and advance char pointers).
  line_buffer_.clear();
  if (!std::getline(input_stream, line_buffer_) &&
      (!input_stream.eof() || input_stream.bad())) {
    std::cerr << "error reading hypergraph text input" << std::endl;
    std::exit(EXIT_FAILURE);
  }
  if (line_buffer_.size() >=
      static_cast<std::size_t>(std::numeric_limits<int>::max())) {
    std::cerr << "hypergraph text line exceeds the converter's integer range"
              << std::endl;
    std::exit(EXIT_FAILURE);
  }
  length = static_cast<int>(line_buffer_.size());
  if (buffer.size() < line_buffer_.size() + 1)
    buffer.resize(line_buffer_.size() + 1);
  std::memcpy(buffer.data(), line_buffer_.c_str(), line_buffer_.size() + 1);
}

#endif
