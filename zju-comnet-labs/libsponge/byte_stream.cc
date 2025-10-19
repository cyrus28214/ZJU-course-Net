#include "byte_stream.hh"

// Dummy implementation of a flow-controlled in-memory byte stream.

// For Lab 0, please replace with a real implementation that passes the
// automated checks run by `make check_lab0`.

// You will need to add private members to the class declaration in `byte_stream.hh`

template <typename... Targs>
void DUMMY_CODE(Targs &&... /* unused */) {}

using namespace std;

ByteStream::ByteStream(const size_t capacity) 
    : _buffer(""), _capacity(capacity), _input_ended(false), _bytes_written(0), _bytes_read(0) {}

size_t ByteStream::write(const string &data) {
    if (_input_ended || _error) {
        return 0;
    }
    
    size_t available_space = remaining_capacity();
    size_t bytes_to_write = min(data.size(), available_space);
    
    _buffer += data.substr(0, bytes_to_write);
    _bytes_written += bytes_to_write;
    
    return bytes_to_write;
}

//! \param[in] len bytes will be copied from the output side of the buffer
string ByteStream::peek_output(const size_t len) const {
    size_t bytes_to_peek = min(len, buffer_size());
    return _buffer.substr(0, bytes_to_peek);
}

//! \param[in] len bytes will be removed from the output side of the buffer
void ByteStream::pop_output(const size_t len) {
    size_t bytes_to_pop = min(len, buffer_size());
    _buffer.erase(0, bytes_to_pop);
    _bytes_read += bytes_to_pop;
}

//! Read (i.e., copy and then pop) the next "len" bytes of the stream
//! \param[in] len bytes will be popped and returned
//! \returns a string
std::string ByteStream::read(const size_t len) {
    string result = peek_output(len);
    pop_output(len);
    return result;
}

void ByteStream::end_input() {
    _input_ended = true;
}

bool ByteStream::input_ended() const { 
    return _input_ended; 
}

size_t ByteStream::buffer_size() const { 
    return _buffer.size(); 
}

bool ByteStream::buffer_empty() const { 
    return _buffer.empty(); 
}

bool ByteStream::eof() const { 
    return _input_ended && buffer_empty(); 
}

size_t ByteStream::bytes_written() const { 
    return _bytes_written; 
}

size_t ByteStream::bytes_read() const { 
    return _bytes_read; 
}

size_t ByteStream::remaining_capacity() const { 
    return _capacity - _buffer.size(); 
}
