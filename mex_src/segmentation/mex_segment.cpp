#include <opencv2/opencv.hpp>
#include "segment.h"
#include "mex.h"
#include "mex_utils.hpp"


void mexFunction( int nlhs, mxArray *plhs[], int nrhs, const mxArray*prhs[] ) {

	if(nrhs < 4) mexErrMsgTxt("Valid input: [image], [fghist], [bghist], bins, ([fg_prior], [bg_prior]) ");
    if(nlhs > 3) mexErrMsgTxt("Too many oputput arguments.");


    int bins = static_cast<int>(mxGetScalar(prhs[3]));
    cv::Mat img = toMat(prhs[0], CV_8U, true);

    cv::Mat fg_prior, bg_prior;
    if (nrhs > 4)
        fg_prior = toMat(prhs[4], CV_64F, true);
    if (nrhs > 5)
        bg_prior = toMat(prhs[5], CV_64F, true);

    std::vector<cv::Mat> imgChannels;
    cv::split(img, imgChannels);

    int ndim = mxGetNumberOfDimensions(prhs[0]);
    if(ndim == 2) {
        ndim = 1;
    }

    double *ptr_fg;
    ptr_fg = (double *) mxGetData(prhs[1]);
    Histogram fg_hist(ndim, bins);
    fg_hist.setHistogramVector(ptr_fg);

    double *ptr_bg;
    ptr_bg = (double *) mxGetData(prhs[2]);
    Histogram bg_hist(ndim, bins);
    bg_hist.setHistogramVector(ptr_bg);

    std::pair<cv::Mat, cv::Mat> probs = Segment::computePosteriors(imgChannels, fg_prior, bg_prior, fg_hist, bg_hist, bins);
    
    if (nlhs > 0) {
        probs.first.convertTo(probs.first, CV_32F);
        probs.second.convertTo(probs.second, CV_32F);

        cv::Mat mask(probs.first.rows, probs.first.cols, CV_8UC1);
        cv::threshold(probs.first/probs.second, mask, 1, 255, cv::THRESH_BINARY);

        plhs[0] = toMxArray(mask, mxLOGICAL_CLASS, true);
    }

    if (nlhs > 1)
        plhs[1] = toMxArray(probs.first, mxSINGLE_CLASS, true);

    if (nlhs > 2)
        plhs[2] = toMxArray(probs.second, mxSINGLE_CLASS, true);

}
