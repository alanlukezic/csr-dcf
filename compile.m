% compile hog and segmetation mex files
% before compiling set the following variables to the correct paths:
% opencv_include and opencv_libpath

current_folder = pwd;
mkdir('mex');

cd(['mex_src' filesep 'hog']);
mex gradientMex.cpp
movefile('*.mex*', [current_folder filesep 'mex'])
cd(current_folder);

if ispc     % Windows machine
    % set opencv include path
    opencv_include = 'E:\development\opencv-2.4.12\opencv\build\include\';
    % set opencv lib path
    opencv_libpath = 'E:\development\opencv-2.4.12\opencv\build\x64\vc11\lib\';

    files = dir([opencv_libpath '*opencv*.lib']);
    lib = [];
    for i = 1:length(files),
        lib = [lib ' -l' files(i).name(1:end-4)];
    end

    cd(['mex_src' filesep 'segmentation']);
    eval(['mex mex_extractforeground.cpp src\segment.cpp -Isrc\ -I' opencv_include ' -L' opencv_libpath ' ' lib]);
    eval(['mex mex_extractbackground.cpp src\segment.cpp -Isrc\ -I' opencv_include ' -L' opencv_libpath ' ' lib]);
    eval(['mex mex_segment.cpp src\segment.cpp -Isrc\ -I' opencv_include ' -L' opencv_libpath ' ' lib]);
    movefile('*.mex*', [current_folder filesep 'mex'])
    cd(current_folder);

elseif isunix   % Unix machine
    % set opencv include path
    opencv_include = '/usr/local/include/';
    % set opencv lib path
    opencv_libpath = '/usr/lib/x86_64-linux-gnu/';

    lib = [];
    files = dir([opencv_libpath '*opencv*.so']);
    for i = 1:length(files)
        lib = [lib ' -l' files(i).name(4:end-3)];
    end

    cd(['mex_src' filesep 'segmentation']);
    eval(['mex mex_extractforeground.cpp src/segment.cpp -Isrc/ -I' opencv_include ' -L' opencv_libpath ' ' lib]);
    eval(['mex mex_extractbackground.cpp src/segment.cpp -Isrc/ -I' opencv_include ' -L' opencv_libpath ' ' lib]);
    eval(['mex mex_segment.cpp src/segment.cpp -Isrc/ -I' opencv_include ' -L' opencv_libpath ' ' lib]);
    movefile('*.mex*', [current_folder filesep 'mex'])
    cd(current_folder);

end
