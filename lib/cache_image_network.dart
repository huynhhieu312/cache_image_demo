import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class MyCacheManager {
  final defaultCacheManager = DefaultCacheManager();

  Future<String> cacheImage(String imagePath) async {
    final pathLink = imagePath;

    final fileCache =
        (await defaultCacheManager.getFileFromCache(pathLink))?.file;
    if (fileCache == null) {
      final path = await _fileFromImageUrl(imagePath);
      return path;
    } else {
      return fileCache.path;
    }

    //return pathLink;

    // Return image download url
  }

  Future<File?> getFileFromCache(String imagePath) async {
    final paths = imagePath.split('/');
    final documentDirectory = await getApplicationDocumentsDirectory();
    final file = File(join(documentDirectory.path, paths.last));
    return file;
  }

  Future<String> _fileFromImageUrl(String imagePath) async {
    final paths = imagePath.split('.');

    // final response = await http.get(Uri.parse(ApiPath.hostCDN + imagePath));
    Dio dio = Dio();
    // print("fileExtension ${paths.last}");
    // print("save file $pathLink");
    //final response = await http.get(Uri.parse(ApiPath.hostCDN + imagePath));
    try {
      Response response = await dio.get(
        imagePath,
        onReceiveProgress: showDownloadProgress,
        //Received data with List<int>
        options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) {
              return (status ?? 0) < 400;
            }),
      );

      final cacheFile = await defaultCacheManager.putFile(
        imagePath,
        response.data,
        fileExtension: paths.last,
      );
      //if cacheFile.
      final isSavedCached = await cacheFile.exists();
      if (isSavedCached) {
        // print("cache file path : ${cacheFile.path}");
        return cacheFile.path;
      } else {
        return imagePath;
      }
    } catch (e) {
      return "error";
    }

    //   return pathLink;
  }

  void showDownloadProgress(received, total) {
    if (total != -1) {
      print((received / total * 100).toStringAsFixed(0) + "%");
    }
  }
}

class CachedImageNetwork extends StatefulWidget {
  final String image;
  final BoxFit? boxFit;
  final FilterQuality? filterQuality;
  final Widget? loading;
  final Widget? errorBuilder;
  final double? height;
  final double? width;
  final VoidCallback? onclick;
  final int? indexHero;
  final bool borderAll;
  final double? borderRadius;
  final bool isBanner;

  CachedImageNetwork(
      {super.key,
      this.indexHero,
      this.onclick,
      required this.image,
      this.boxFit,
      this.filterQuality,
      this.loading,
      this.errorBuilder,
      this.width,
      this.height,
      this.borderAll = true,
      this.borderRadius,
      this.isBanner = false});

  @override
  _CachedImageNetworkState createState() => _CachedImageNetworkState();
}

class _CachedImageNetworkState extends State<CachedImageNetwork> {
  String _imageUrl = "";
  bool nonImage = false;
  @override
  void initState() {
    final myCacheManager = MyCacheManager();
    if (widget.image.isNotEmpty) {
      nonImage = false;
      myCacheManager.cacheImage(widget.image).then((String imageUrl) {
        if (mounted) {
          setState(() {
            // Get image url
            _imageUrl = imageUrl;
          });
        }
      });
    } else {
      if (mounted) {
        setState(() {
          // Get image url
          nonImage = true;
        });
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return nonImage == false
        ? ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(widget.borderRadius ?? 0.0),
              topRight: Radius.circular(widget.borderRadius ?? 0.0),
              bottomLeft: widget.borderAll
                  ? Radius.circular(widget.borderRadius ?? 0.0)
                  : Radius.circular(0),
              bottomRight: widget.borderAll
                  ? Radius.circular(widget.borderRadius ?? 0.0)
                  : Radius.circular(0),
            ),
            child: _imageUrl != ""
                ? !_imageUrl.contains("https")
                    ? Image.file(fit: BoxFit.fill, File(_imageUrl),
                        errorBuilder: (context, error, trace) {
                        return Icon(Icons.error);
                      })
                    : _imageUrl.contains("error")
                        ? Icon(Icons.error)
                        : CachedNetworkImage(
                            fit: BoxFit.fill,
                            imageUrl: _imageUrl,
                            placeholder: (context, url) =>
                                CommonCircularProgressIndicator(),
                            errorWidget: (context, url, error) {
                              print("errror url banner $url");
                              return CommonCircularProgressIndicator();
                            },
                          )
                : CommonCircularProgressIndicator())
        : CommonCircularProgressIndicator();
  }

  bool checkIfImage(String param) {
    if (param == 'image/jpeg' || param == 'image/png' || param == 'image/gif') {
      return true;
    }
    return false;
  }
}

class CommonCircularProgressIndicator extends StatelessWidget {
  const CommonCircularProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.grey.withOpacity(0.8),
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor:
            AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
      ),
    );
  }
}
