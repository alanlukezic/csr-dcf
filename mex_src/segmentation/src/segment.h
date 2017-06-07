#ifndef __SEGMENT_H__32463287463294198743982173
#define __SEGMENT_H__32463287463294198743982173

#include <opencv2/opencv.hpp>
#include <vector>

#ifndef M_PI
#define M_PI 3.14
#endif

class Histogram
{
public:
    int m_numBinsPerDim;
    int m_numDim;

    Histogram() : m_numBinsPerDim(0), m_numDim(0) {}
    Histogram(int numDimensions, int numBinsPerDimension = 8);
    void extractForegroundHistogram(std::vector<cv::Mat> & imgChannels, cv::Mat weights, bool useMatWeights, int x1, int y1, int x2, int y2);
    void extractBackGroundHistogram(std::vector<cv::Mat> & imgChannels, int x1, int y1, int x2, int y2, int outer_x1, int outer_y1, int outer_x2, int outer_y2);
    cv::Mat backProject(std::vector<cv::Mat> & imgChannels);
    std::vector<double> getHistogramVector();
    void setHistogramVector(double *vector);

private:
    int p_size;
    std::vector<double> p_bins;
    std::vector<int> p_dimIdCoef;

    inline double kernelProfile_Epanechnikov(double x)
        { return (x <= 1) ? (2.0/3.14)*(1-x) : 0; }
};


class Segment
{
public:
    static std::pair<cv::Mat, cv::Mat> computePosteriors(std::vector<cv::Mat> &imgChannels, cv::Mat fgPrior, cv::Mat bgPrior, Histogram hist_target, Histogram hist_background, int numBinsPerChannel = 16);


private:
    static std::pair<cv::Mat, cv::Mat> getRegularizedSegmentation(cv::Mat & prob_o, cv::Mat & prob_b, cv::Mat &prior_o, cv::Mat &prior_b);

    inline static double gaussian(double x2, double y2, double std2){
        return exp(-(x2 + y2)/(2*std2))/(2*M_PI*std2);
    }

};


#endif // __SEGMENT_H__32463287463294198743982173
