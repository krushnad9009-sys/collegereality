import 'package:flutter/material.dart';

void main() {
  runApp(const CollegeRealityIndia());
}

class CollegeRealityIndia extends StatelessWidget {
  const CollegeRealityIndia({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const DashboardPage(),
    );
  }
}


class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});


  @override
  Widget build(BuildContext context){

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Student Dashboard",
        ),
      ),


      body: GridView.count(

        padding: const EdgeInsets.all(20),

        crossAxisCount:2,

        crossAxisSpacing:15,

        mainAxisSpacing:15,


        children:[


          dashboardCard(
            context,
            Icons.star,
            "College Rating",
            const SurveyPage(),
          ),


          dashboardCard(
            context,
            Icons.school,
            "College Search",
            null,
          ),


          dashboardCard(
            context,
            Icons.rate_review,
            "Reviews",
            null,
          ),


          dashboardCard(
            context,
            Icons.work,
            "Jobs & Internship",
            null,
          ),


          dashboardCard(
            context,
            Icons.people,
            "Student Community",
            null,
          ),


          dashboardCard(
            context,
            Icons.person,
            "My Profile",
            null,
          ),

        ],

      ),

    );

  }



  Widget dashboardCard(
      BuildContext context,
      IconData icon,
      String title,
      Widget? page
      ){

    return Card(

      elevation:5,

      child:InkWell(

        onTap:(){

          if(page!=null){

            Navigator.push(
              context,
              MaterialPageRoute(
                builder:(context)=>page,
              ),
            );

          }

        },


        child:Column(

          mainAxisAlignment:MainAxisAlignment.center,

          children:[


            Icon(
              icon,
              size:45,
              color:Colors.indigo,
            ),


            const SizedBox(height:10),


            Text(
              title,
              textAlign:TextAlign.center,
            )


          ],

        ),

      ),

    );

  }

}



class SurveyPage extends StatelessWidget{

  const SurveyPage({super.key});


  @override
  Widget build(BuildContext context){

    return Scaffold(

      appBar:AppBar(
        title:const Text(
          "College Rating Survey",
        ),
      ),


      body:const Center(

        child:Text(
          "Rating Questions Page",
          style:TextStyle(
            fontSize:25,
          ),
        ),

      ),

    );

  }

}