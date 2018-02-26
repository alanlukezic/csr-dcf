# Discriminative Correlation Filter with Channel and Spatial Reliability

Matlab implementation of the DCF-CSR tracker from the paper published in the proceedings of Conference on Computer Vision and Pattern Recognition (CVPR) 2017 and later in International Journal of Computer Vision (IJCV).

## Publications
Journal publication: </br>
Alan Lukežič, Tomáš Vojíř, Luka Čehovin, Jiří Matas and Matej Kristan. ''Discriminative Correlation Filter Tracker with Channel and Spatial Reliability.'' International Journal of Computer Vision (IJCV), 2018.</br>
[Paper](https://arxiv.org/abs/1611.08461) </br>

<b>BibTex citation:</b></br>
@Article{Lukezic_IJCV2018,</br>
author={Luke{\v{z}}i{\v{c}}, Alan and Voj{\'i}{\v{r}}, Tom{\'a}{\v{s}} and {\v{C}}ehovin Zajc, Luka and Matas, Ji{\v{r}}{\'i} and Kristan, Matej},</br>
title={Discriminative Correlation Filter Tracker with Channel and Spatial Reliability},</br>
journal={International Journal of Computer Vision},</br>
year={2018},</br>
}

Raw results: [VOT15](http://data.vicos.si/alanl/CSR-DCF-VOT15.zip) [VOT16](http://data.vicos.si/alanl/CSR-DCF-VOT16.zip) [OTB100](http://data.vicos.si/alanl/CSR-DCF-results-OTB100.zip)

Conference publication: </br>
Alan Lukežič, Tomáš Vojíř, Luka Čehovin, Jiří Matas and Matej Kristan. ''Discriminative Correlation Filter with Channel and Spatial Reliability.'' In Proceedings of the IEEE Conference on Computer Vision and Pattern Recognition (CVPR), 2017.</br>
[Paper](http://openaccess.thecvf.com/content_cvpr_2017/papers/Lukezic_Discriminative_Correlation_Filter_CVPR_2017_paper.pdf) </br>

<b>BibTex citation:</b></br>
@InProceedings{Lukezic_CVPR_2017,<br>
Title = {Discriminative Correlation Filter with Channel and Spatial Reliability},<br>
Author = {Luke{\v{z}}i{\v{c}}, Alan and Voj{\'i}{\v{r}}, Tom{\'a}{\v{s}} and {\v{C}}ehovin Zajc, Luka and Matas, Ji{\v{r}}{\'i} and Kristan, Matej},<br>
Booktitle = {CVPR},<br>
Year = {2017}<br>
}

## Contacts

Alan Lukežič, e-mail: alan.lukezic@fri.uni-lj.si </br>
Tomáš Vojíř, e-mail: vojirtom@cmp.felk.cvut.cz </br>
Luka Čehovin Zajc, e-mail: luka.cehovin@fri.uni-lj.si </br>

## Installation and demo
* Clone git repository: </br>
    $ git clone https://github.com/alanlukezic/csr-dcf.git
* Compile mex files running compile.m command </br>
	Set <i>opencv_include</i> and <i>opencv_libpath</i> to the correct OpenCV paths
* Use demo_csr.m script for the visualization of the tracker </br>
	Set <i>tracker_path</i> variable to the directory where your source code is and <i>base_path</i> to the directory where you have stored the VOT sequences.
* Use csr_wrapper.m script for VOT integration

## C++ Implementation

The C++ version of the CSR-DCF tracker is now available in OpenCV contrib repository (tracking module, CSRT tracker)

## Project summary
Short-term tracking is an open and challenging problem for which discriminative correlation filters (DCF) have shown excellent performance. We introduce the channel and spatial reliability concepts to DCF tracking and provide a novel learning algorithm for its efficient and seamless integration in the filter update and the tracking process. The spatial reliability map adjusts the filter support to the part of the object suitable for tracking. This both allows to enlarge the search region and improves tracking of non-rectangular objects. Reliability scores reflect channel-wise quality of the learned filters and are used as feature weighting coefficients in localization. Experimentally, with only two simple standard features, HoGs and Colornames, the novel CSR-DCF method -- DCF with Channel and Spatial Reliability -- achieves state-of-the-art results on VOT 2016, VOT 2015 and OTB100. The CSR-DCF runs in real-time on a CPU.

<p style="width:100%, text-align:center"><a href="url"><img src="https://user-images.githubusercontent.com/12802864/26883749-54b16eae-4b9e-11e7-8506-94c211331218.png" width="480"></a></p>

## VOT Results
Tracking results on the VOT-2015 benchmark:
<div>
<a href="url"><img src="https://user-images.githubusercontent.com/12802864/26885137-0fa669dc-4ba2-11e7-8b41-52adfdfcf767.PNG" text-align="left" width="400"></a>
</div>

Tracking results on the VOT-2016 benchmark:
<div>
<a href="url"><img src="https://user-images.githubusercontent.com/12802864/26885151-1a6049c4-4ba2-11e7-9c30-0c3bf0f87943.PNG" text-align="right" width="400"></a>
</div>

Raw VOT results: [VOT15](http://data.vicos.si/alanl/CSR-DCF-VOT15.zip) [VOT16](http://data.vicos.si/alanl/CSR-DCF-VOT16.zip)

## Video
Click <a href="https://www.youtube.com/watch?v=Yl-grwGch_M">here</a> to see demo video on YouTube.
