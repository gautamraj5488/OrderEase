import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:dms/utils/helpers/helper_fuctions.dart';
import 'package:dms/utils/theme/custom_theme/text_theme.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../services/chat/chat_service.dart';
import '../../../../services/firestore.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';


class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ChatService _chatService = ChatService();
  final FireStoreServices _fireStoreServices = FireStoreServices();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late List<Map<String, dynamic>> _userList;
  late List<Map<String, dynamic>> _filteredUserList;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _userList = [];
    _filteredUserList = [];
    _initializeUserList();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _initializeUserList() async {
    final userList = await _chatService.getUsersList();
    setState(() {
      _userList = userList;
      _filteredUserList = userList;
    });
  }

  void _onSearchChanged() {
    String query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredUserList = _userList
          .where((user) =>
      user['firstName'].toLowerCase().contains(query) ||
          user['lastName'].toLowerCase().contains(query))
          .toList();
    });
  }

  Future<void> _refresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                itemCount: _filteredUserList.length,
                itemBuilder: (context, index) {
                  return StreamBuilder(
                    stream: _chatService.getUsersStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Image.asset("assets/gifs/loading.gif"),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Image.asset("assets/gifs/loading.gif"),
                        );
                      }
                      // return list view
                      return Container(
                        height: 100,
                        width: 100,
                        color: Colors.deepPurple[400],
                      ); // ListView
                    },
                  );
                  //return _buildUserListItem(_filteredUserList[index], context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}



