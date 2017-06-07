#include <opencv2/opencv.hpp>

#ifndef __MEX_UTILS_H
#define __MEX_UTILS_H


/** std::map wrapper with one-line initialization and lookup method.
 * Initialization
 * @code
 * const ConstMap<std::string,int> BorderType = ConstMap<std::string,int>
 *     ("Replicate",  cv::BORDER_REPLICATE)
 *     ("Constant",   cv::BORDER_CONSTANT)
 *     ("Reflect",    cv::BORDER_REFLECT);
 * @endcode
 * Lookup
 * @code
 * BorderType["Constant"] // => cv::BORDER_CONSTANT
 * @endcode
 */
template <typename T, typename U>
class ConstMap
{
  public:
    /// Constructor with a single key-value pair
    ConstMap(const T& key, const U& val)
    {
        m_[key] = val;
    }
    /// Consecutive insertion operator
    ConstMap<T, U>& operator()(const T& key, const U& val)
    {
        m_[key] = val;
        return *this;
    }
    /// Implicit converter to std::map
    operator std::map<T, U>() { return m_; }
    /// Lookup operator; fail if not found
    U operator [](const T& key) const
    {
        typename std::map<T,U>::const_iterator it = m_.find(key);
        if (it==m_.end())
            mexErrMsgIdAndTxt("mexopencv:error", "Value not found");
        return (*it).second;
    }
  private:
    std::map<T, U> m_;
};


/** Translates data type definition used in OpenCV to that of Matlab.
 * @param classid data type of matlab's mxArray. e.g., mxDOUBLE_CLASS.
 * @return opencv's data type. e.g., CV_8U.
 */
const ConstMap<mxClassID, int> DepthOf = ConstMap<mxClassID, int>
    (mxDOUBLE_CLASS,   CV_64F)
    (mxSINGLE_CLASS,   CV_32F)
    (mxINT8_CLASS,     CV_8S)
    (mxUINT8_CLASS,    CV_8U)
    (mxINT16_CLASS,    CV_16S)
    (mxUINT16_CLASS,   CV_16U)
    (mxINT32_CLASS,    CV_32S)
    (mxUINT32_CLASS,   CV_32S)
    (mxLOGICAL_CLASS,  CV_8U);


/** Translates data type definition used in Matlab to that of OpenCV.
 * @param depth data depth of opencv's Mat class. e.g., CV_32F.
 * @return data type of matlab's mxArray. e.g., mxDOUBLE_CLASS.
 */
const ConstMap<int,mxClassID> ClassIDOf = ConstMap<int,mxClassID>
    (CV_64F,    mxDOUBLE_CLASS)
    (CV_32F,    mxSINGLE_CLASS)
    (CV_8S,     mxINT8_CLASS)
    (CV_8U,     mxUINT8_CLASS)
    (CV_16S,    mxINT16_CLASS)
    (CV_16U,    mxUINT16_CLASS)
    (CV_32S,    mxINT32_CLASS);


mxArray* toMxArray(const cv::Mat& mat, mxClassID classid, bool transpose)
{
    mxArray* data = NULL;

    if (mat.empty())
    {
        data = mxCreateNumericArray(0, 0, mxDOUBLE_CLASS, mxREAL);
        if (!data)
            mexErrMsgIdAndTxt("mexsegment:error", "Allocation error");
        return NULL;
    }
    cv::Mat input = (mat.dims == 2 && transpose) ? mat.t() : mat;
    // Create a new mxArray.
    const int nchannels = input.channels();
    const int* dims_ = input.size;
    std::vector<mwSize> d(dims_, dims_ + input.dims);
    d.push_back(nchannels);
    classid = (classid == mxUNKNOWN_CLASS)
        ? ClassIDOf[input.depth()] : classid;
    std::swap(d[0], d[1]);
    if (classid == mxLOGICAL_CLASS)
    {
        // OpenCV's logical true is any nonzero while matlab's true is 1.
        cv::compare(input, 0, input, cv::CMP_NE);
        input.setTo(1, input);
        data = mxCreateLogicalArray(d.size(), &d[0]);
    }
    else {
        data = mxCreateNumericArray(d.size(), &d[0], classid, mxREAL);
    }
    if (!data)
        mexErrMsgIdAndTxt("mexsegment:error", "Allocation error");
    // Copy each channel.
    std::vector<cv::Mat> channels;
    split(input, channels);
    std::vector<mwSize> si(d.size(), 0); // subscript index.
    int type = CV_MAKETYPE(DepthOf[classid], 1); // destination type.
    for (int i = 0; i < nchannels; ++i)
    {
        si[si.size() - 1] = i; // last dim is a channel index.
        void *ptr = reinterpret_cast<void*>(
                reinterpret_cast<size_t>(mxGetData(data)) +
                mxGetElementSize(data) * mxCalcSingleSubscript(data, si.size(), &si[0]));
        cv::Mat m(input.dims, dims_, type, ptr);
        channels[i].convertTo(m, type); // Write to mxArray through m.
    }

    return data;
}


cv::Mat toMat(const mxArray* data, int depth, bool transpose)
{
    mwSize mxndims = mxGetNumberOfDimensions(data);
    const mwSize* mxdims = mxGetDimensions(data);
    mxClassID classID = mxGetClassID(data);

    // Create cv::Mat object.
    std::vector<int> d(mxdims , mxdims + mxndims);
    int ndims = (d.size()>2) ? d.size()-1 : d.size();
    int nchannels = (d.size()>2) ? *(d.end()-1) : 1;
    depth = (depth==CV_USRTYPE1) ? DepthOf[classID] : depth;
    std::swap(d[0], d[1]);
    cv::Mat mat(ndims, &d[0], CV_MAKETYPE(depth, nchannels));
    // Copy each channel.
    std::vector<cv::Mat> channels(nchannels);
    std::vector<mwSize> si(d.size(), 0); // subscript index
    int type = CV_MAKETYPE(DepthOf[classID], 1); // Source type
    for (int i = 0; i<nchannels; ++i)
    {
        si[d.size()-1] = i;
        void *pd = reinterpret_cast<void*>(
                reinterpret_cast<size_t>(mxGetData(data))+
                mxGetElementSize(data)*mxCalcSingleSubscript(data, si.size(), &si[0]));
        cv::Mat m(ndims, &d[0], type, pd);
        // Read from mxArray through m
        m.convertTo(channels[i], CV_MAKETYPE(depth, 1));
    }
    cv::merge(channels, mat);
    return (mat.dims==2 && transpose) ? cv::Mat(mat.t()) : mat;
}

#endif // __MEX_UTILS_H
