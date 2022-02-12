import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photoapp/Screen/Component/ui_component.dart';
import 'package:photoapp/Screen/gallery_item_widget.dart';
import 'package:photoapp/bolc/gallery_cubit.dart';
import 'package:photoapp/bolc/gallery_state.dart';


List<int> itemToDelete = [];
class Gallery extends StatefulWidget {
  const Gallery({Key? key}) : super(key: key);
  static const routeName = "screenGallery";

  @override
  _GalleryState createState() => _GalleryState();
}

class _GalleryState extends State<Gallery> {

  List<AssetEntity> assets = [];
  late BuildContext scaffoldContext;
  late GalleryCubit _galleryCubit;

  @override
  void didChangeDependencies(){
    _galleryCubit = BlocProvider.of<GalleryCubit>(context);
    PhotoManager.requestPermission().then((permitted){
      if (permitted) {
        _galleryCubit.fetchAssets();
      } else {
        showInSnackBar();
      }
    });
    super.didChangeDependencies();
  }

  void showInSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Permission Denied'),
    ));
  }

  @override
  Widget build(BuildContext context) {

    Color commonColor = Colors.brown;

    return Scaffold(
      appBar: AppBar(
        title:  Text('PhotoApp' ,style: TextStyle(color: commonColor), ),
        backgroundColor: Colors.white,
        actions: [
          BlocBuilder<GalleryCubit, GalleryState>(builder: (context, state) {
            if (state is GalleryFetchSuccess) {
              return IconButton(
                  onPressed: () {
                    if (state.deleteMode) {
                      if(itemToDelete.isNotEmpty) {
                        Ui.showConfirmationAlert(context,  () async {
                          Ui.showLoadingDialog(context);

                          try{
                            await Future.wait(itemToDelete.map((element)async {
                              String ids =  assets[element].id;
                              await PhotoManager.editor.deleteWithIds([ids]);

                            }));
                          }catch(error){
                            print("ERROR: "+error.toString());
                          }
                          itemToDelete.clear();
                          _galleryCubit.changeDeleteMode(false);
                          _galleryCubit.fetchAssets();
                          Navigator.of(context).pop();
                      });
                      }
                      else{
                        _galleryCubit.changeDeleteMode(false);
                      }

                    } else {
                      _galleryCubit.changeDeleteMode(true);
                    }
                  },
                  icon: Icon(
                    state.deleteMode ? Icons.check : Icons.delete_forever_sharp,
                    color: commonColor,
                  ));
            } else {
              return const SizedBox();
            }
          })
        ],
      ),
      body: Builder(
          builder: (context) {
            scaffoldContext = context;
            return BlocBuilder<GalleryCubit, GalleryState>(
                builder: (context, state) {
                  if(state is GalleryLoading) {
                    return const Center(child:  CircularProgressIndicator());
                  }
                  else if(state is GalleryFetchSuccess){
                    assets.clear();
                    assets.addAll(state.assets);
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4),
                      itemCount: assets.length+1,
                      itemBuilder: (_, index){
                        if(index==0) {
                          return IconButton(onPressed:(){
                            _takePhoto();
                          }, icon: Icon(Icons.camera_alt,color: commonColor,));
                        }
                        else {
                          AssetEntity asset = assets[index -1];
                          return GalleryItem(asset, index-1);

                    }
                  },
                );
                  }
                  else{return const SizedBox();}
              }
            );
          }
      ),
    );
  }

  void _takePhoto() async {
    ImagePicker().pickImage(source: ImageSource.camera)
        .then((recordedImage) async {
      if (recordedImage != null) {
        Ui.showLoadingDialog(context);
        await ImageGallerySaver.saveFile(recordedImage.path);

        Future.delayed(const Duration(seconds: 2),(){
          BlocProvider.of<GalleryCubit>(context).fetchAssets();
          Navigator.of(context).pop();
        });
      }
    });
  }

}