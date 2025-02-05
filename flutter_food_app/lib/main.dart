import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MealProvider(),
      child: MaterialApp(
        title: 'Food Catalog',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MealProvider extends ChangeNotifier {
  List<Map<String, dynamic>> meals = [];
  List<Map<String, dynamic>> favorites = [];

  Future<void> fetchMeals(String query) async {
    if (query.isEmpty) {
      meals = [];
      notifyListeners();
      return;
    }
    final response = await http.get(Uri.parse('https://www.themealdb.com/api/json/v1/1/search.php?s=$query'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      meals = data['meals'] != null
          ? (data['meals'] as List)
              .map((meal) => {
                    'name': meal['strMeal'],
                    'image': meal['strMealThumb'],
                  })
              .toList()
          : [];
      notifyListeners();
    }
  }

  void toggleFavorite(Map<String, dynamic> meal) {
    if (favorites.contains(meal)) {
      favorites.remove(meal);
    } else {
      favorites.add(meal);
    }
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    Widget page = selectedIndex == 0 ? MealsPage() : FavoritesPage();
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: Row(
            children: [
              SafeArea(
                child: NavigationRail(
                  extended: constraints.maxWidth >= 600,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  destinations: [
                    NavigationRailDestination(icon: Icon(Icons.restaurant), label: Text('Meals')),
                    NavigationRailDestination(icon: Icon(Icons.favorite), label: Text('Favorites')),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.orange[50],
                  child: page,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MealsPage extends StatefulWidget {
  @override
  _MealsPageState createState() => _MealsPageState();
}

class _MealsPageState extends State<MealsPage> {
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var mealProvider = context.watch<MealProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search for a meal',
              border: OutlineInputBorder(),
            ),
            onChanged: (query) {
              mealProvider.fetchMeals(query);
            },
          ),
        ),
        Expanded(
          child: mealProvider.meals.isEmpty
              ? Center(child: Text('Type a meal name to search.'))
              : ListView.builder(
                  itemCount: mealProvider.meals.length,
                  itemBuilder: (context, index) {
                    var meal = mealProvider.meals[index];
                    return MealItem(meal: meal);
                  },
                ),
        ),
      ],
    );
  }
}

class MealItem extends StatelessWidget {
  final Map<String, dynamic> meal;
  
  MealItem({required this.meal});

  @override
  Widget build(BuildContext context) {
    var mealProvider = context.watch<MealProvider>();
    
    return Card(
      color: Colors.white,
      margin: EdgeInsets.all(8.0),
      child: ListTile(
        leading: Image.network(meal['image']!),
        title: Text(meal['name']!),
        trailing: IconButton(
          icon: Icon(mealProvider.favorites.contains(meal) ? Icons.favorite : Icons.favorite_border),
          onPressed: () => mealProvider.toggleFavorite(meal),
        ),
      ),
    );
  }
}


class FavoritesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var mealProvider = context.watch<MealProvider>();
    if (mealProvider.favorites.isEmpty) {
      return Center(child: Text('No favorites yet.'));
    }
    return ListView.builder(
      itemCount: mealProvider.favorites.length,
      itemBuilder: (context, index) {
        var meal = mealProvider.favorites[index];
        return Card(
          color: Colors.white,
          margin: EdgeInsets.all(8.0),
          child: ListTile(
            leading: Image.network(meal['image']!),
            title: Text(meal['name']!),
          ),
        );
      },
    );
  }
}
