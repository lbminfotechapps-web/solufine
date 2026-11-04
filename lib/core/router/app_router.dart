import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_acess_bloc.dart';
import 'package:solufine/features/home/presentation/advertisement.dart';
import 'package:solufine/features/meeting/presentation/pages/meetingpage.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/bloc/complaint_bloc.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/pages/complaint_form.dart';
import 'package:solufine/features/marketing/dsi/presentation/bloc/dsi_bloc.dart';
import 'package:solufine/features/marketing/dsi/presentation/pages/add_dsi_page.dart';
import 'package:solufine/features/marketing/dsi/presentation/pages/dsi_list_page.dart';
import 'package:solufine/features/marketing/farmer_coupon_booking/presentation/bloc/farmer_coupon_bloc.dart';
import 'package:solufine/features/marketing/farmer_coupon_booking/presentation/pages/farmer_coupon_page.dart';
import 'package:solufine/features/marketing/field_visit/presentation/bloc/field_visit_bloc.dart';
import 'package:solufine/features/marketing/field_visit/presentation/pages/field_visit_page.dart';
import 'package:solufine/features/marketing/jeep_campaign/presentation/bloc/jeep_campaign_bloc.dart';
import 'package:solufine/features/marketing/jeep_campaign/presentation/pages/jeep_campaign_page.dart';
import 'package:solufine/features/marketing/field_day_visit/presentation/bloc/field_day_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:solufine/features/marketing/field_day_visit/presentation/pages/field_day_page.dart';
import 'package:solufine/features/marketing/other_activity_near_dealer/presentation/bloc/dealer_activity_bloc.dart';
import 'package:solufine/features/assigntask/presentation/bloc/assigned_task_bloc.dart';
import 'package:solufine/features/assigntask/presentation/bloc/task_bloc.dart';
import 'package:solufine/features/assigntask/presentation/pages/assign_task_page.dart';
import 'package:solufine/features/assigntask/presentation/pages/assigned_task_list_page.dart';
import 'package:solufine/features/marketing/other_activity_near_dealer/presentation/pages/dealer_activity_page.dart';
import 'package:solufine/features/marketing/success_story/presentation/bloc/success_story_bloc.dart';
import 'package:solufine/features/marketing/success_story/presentation/pages/success_story_page.dart';
import 'package:solufine/features/schedule/domain/entities/schedule_farmer_entity.dart';
import 'package:flutter/material.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/features/ai/presentation/bloc/ai_bloc.dart';
import 'package:solufine/features/ai/presentation/pages/ai_chatbot.dart';
import 'package:solufine/features/calendar_report/presentation/bloc/calendar_report_bloc.dart';
import 'package:solufine/features/calendar_report/presentation/pages/calendar_report_page.dart';
import 'package:solufine/features/consultant_doctors/domain/entities/consultant_doctor.dart';
import 'package:solufine/features/consultant_doctors/presentation/bloc/consultant_bloc.dart';
import 'package:solufine/features/consultant_doctors/presentation/bloc/location_cubit.dart';
import 'package:solufine/features/consultant_doctors/presentation/pages/consultant_form_page.dart';
import 'package:solufine/features/consultant_doctors/presentation/pages/consultant_list_page.dart';
import 'package:solufine/features/growth_report/presentation/bloc/growth_report_bloc.dart';
import 'package:solufine/features/growth_report/presentation/pages/growth_report_page.dart';
import 'package:solufine/features/plant_doctor/presentation/bloc/plant_doctor_bloc.dart';
import 'package:solufine/features/plant_doctor/presentation/pages/plant_doctor_page.dart';
import 'package:solufine/features/plotmesure/plot_measurement_page.dart';
import 'package:solufine/features/quickchartreport/presentation/bloc/gallerybloc.dart'
    as quick_chart;
import 'package:solufine/core/utility/widgets/bottom_navigation.dart';
import 'package:solufine/core/di/auth_di.dart';
import 'package:solufine/features/addexpense/presentation/pages/add_expense_page.dart';
import 'package:solufine/features/assign_target_point_wise/presentation/pages/self_target_page.dart';
import 'package:solufine/features/auth/presentation/pages/change_password.dart';
import 'package:solufine/features/auth/presentation/pages/login_screen.dart';
import 'package:solufine/features/collection/presentation/pages/collection_list_page.dart';
import 'package:solufine/features/collection/presentation/pages/collection_wise_form_page.dart';
import 'package:solufine/features/collection/presentation/pages/dealer_wise_target_page.dart';
import 'package:solufine/features/dealer/data/models/DealerListModel.dart';
import 'package:solufine/features/dealer/presentation/pages/DealerListScreen.dart';
import 'package:solufine/features/dealer/presentation/pages/dealerStocks.dart';
import 'package:solufine/features/dealer_visit/presentation/pages/dealer_followup_list_page.dart';
import 'package:solufine/features/dealer_visit/presentation/pages/dealer_followup_add.dart';
import 'package:solufine/features/dealer_visit/presentation/pages/edit_update_dealer.dart';
import 'package:solufine/features/distpatchistory/presentation/pages/dispatch_page.dart';
import 'package:solufine/features/dealer_visit/presentation/pages/add_remark_page.dart';
import 'package:solufine/features/enquiry/presentation/pages/enquiry_page.dart';
import 'package:solufine/features/expense/presentation/pages/my_expense_page.dart';
import 'package:solufine/features/expense/presentation/pages/team_expense_page.dart';
import 'package:solufine/features/farmer/famerfollowup/presentation/pages/famerfollowuppage.dart';
import 'package:solufine/features/farmer/farmerlist/data/model/farmerlist_model.dart';
import 'package:solufine/features/farmer/farmerregistration/presentation/pages/farmer_edit_update_scren.dart';
import 'package:solufine/features/farmer/farmerlist/presentation/pages/farmerlist_screen.dart';
import 'package:solufine/features/farmer/farmerregistration/presentation/pages/farmerregistration_page.dart';
import 'package:solufine/features/followup/presentation/pages/followup_page.dart';
import 'package:solufine/features/gallery/presentation/pages/galleryscreen.dart';
import 'package:solufine/features/home/presentation/crop_schedule_page.dart';

import 'package:solufine/features/home/presentation/home.dart';
import 'package:solufine/features/home/presentation/punch_screen.dart';
import 'package:solufine/features/home/doman/home_entity/punch_stat_entity.dart';
import 'package:solufine/features/home/presentation/punch_out_screen.dart';
import 'package:solufine/features/home/presentation/social_media_page.dart';
import 'package:solufine/features/leave/presentation/pages/add_leave_page.dart';
import 'package:solufine/features/leave/presentation/pages/leave_list_page.dart';
import 'package:solufine/features/leave/presentation/pages/team_leave_list_page.dart';
import 'package:solufine/features/leave/presentation/pages/top_ten_dealer_page.dart';
import 'package:solufine/features/home/presentation/last_force_out_screen.dart';
import 'package:solufine/features/place_order/presentation/pages/place_order_page.dart';
import 'package:solufine/features/orderhistory/presentation/presentattion/order_history_page.dart';
import 'package:solufine/features/products/domain/entity/fertilizer_category_entity.dart';
import 'package:solufine/features/products/domain/entity/fertilizer_product_entity.dart';
import 'package:solufine/features/products/presentation/pages/product_details.dart';
import 'package:solufine/features/products/presentation/pages/product_list.dart';
import 'package:solufine/features/products/presentation/pages/products_screen.dart';
import 'package:solufine/features/profilepage/profile_page.dart';
import 'package:solufine/features/quickchartreport/presentation/pages/quick_referance_page.dart';
import 'package:solufine/features/report_home_page/report_home_page.dart';
import 'package:solufine/features/reports/presentation/bloc/employee_activity_bloc.dart';
import 'package:solufine/features/reports/presentation/bloc/monthly_performance_bloc.dart';
import 'package:solufine/features/reports/presentation/pages/about_us_page.dart';
import 'package:solufine/features/reports/presentation/pages/contact_us_page.dart';
import 'package:solufine/features/reports/presentation/pages/employee_activity_report_page.dart';
import 'package:solufine/features/reports/presentation/pages/employee_output_report_page.dart';
import 'package:solufine/features/reports/presentation/pages/monthly_performance_report_page.dart';
import 'package:solufine/features/reports/presentation/pages/not_visited_dealer_page.dart';
import 'package:solufine/features/reports/presentation/pages/notification_page.dart';

import 'package:solufine/features/reports/presentation/pages/reports_scree.dart';
import 'package:solufine/features/reports/presentation/pages/user_guidelines_page.dart';
import 'package:solufine/features/reports/presentation/pages/visit_summary_page.dart';
import 'package:solufine/features/reports/presentation/bloc/employee_output_bloc.dart';
import 'package:solufine/features/reports/presentation/bloc/visit_report_bloc.dart';
import 'package:solufine/features/sales_targrt_achievement/presentation/pages/sales_wise_target_page.dart';
import 'package:solufine/features/salesreturn/presentation/pages/sales_return_page.dart';
import 'package:solufine/features/salesreturnhistory/presentation/presentation/sales_return_history_page.dart';
import 'package:solufine/features/plot_registration/presentation/bloc/plot_bloc.dart';
import 'package:solufine/features/plot_registration/presentation/pages/plot_registration_page.dart';
import 'package:solufine/features/schedule/presentation/bloc/farmer_schedule_bloc.dart';
import 'package:solufine/features/schedule/presentation/bloc/schedule_list_bloc.dart';
import 'package:solufine/features/schedule/presentation/pages/farmer_schedule_page.dart';
import 'package:solufine/features/schedule/presentation/pages/schedule_list_page.dart';
import 'package:solufine/features/scheme/presentation/pages/schemescreen.dart';
import 'package:solufine/features/selfcollectionassign/presentation/presentation/assingselfcollectiontarget_page.dart';
import 'package:solufine/features/splash/splash_screen.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:solufine/features/visit_month_wise/presentation/bloc/visit_month_wise_bloc.dart';
import 'package:solufine/features/visit_month_wise/presentation/pages/visit_month_wise_report_page.dart';

class AppRouter {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static const String meeting = '/meeting';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String punch = '/punchIn';
  static const String punchOut = '/punchOut';
  static const String lastPunchOut = '/lastPunchOut';

  static const String noVisitDealer = '/notVisitDealer';

  static const String home = '/home';
  static const String followup = '/followup';
  static const String visits = '/visits';
  static const String products = '/products';
  static const String monthlyPerformanceReport = '/monthlyPerformanceReport';

  static const String reportPage = '/reportPage';
  static const String monthlyVisitPerformanceReport =
      '/monthlyVisitPerformanceReport';
  static const String calendarReport = '/calendarReport';
  static const String productList = '/productList';
  static const String productDetails = '/productDetails';
  static const String farmers = '/farmers';
  static const String farmerpin = '/farmerpin';
  static const String dealerpin = '/dealerpin';

  static const String empActivityReport = '/empActivityReport';
  static const String empOutputReport = '/empOutputReport';
  static const String visitSummaryReport = '/visitSummaryReport';
  static const String plotmeasurement = '/plotmeasurement';

  static const String aboutUs = '/aboutUs';
  static const String changePassword = '/changePassword';
  static const String contactUs = '/contactUs';
  static const String userGuide = '/userGuide';
  static const String notification = '/notification';
  static const String gallery = '/gallery';
  static const String scheme = '/scheme';
  static const String leaveList = '/leaveList';
  static const String addLeave = '/add-Leave';

  static const String topTenDealer = '/topTenDealer';
  static const String social = '/social';
  static const String teamLeaveList = '/teamLeaveList';

  static const String addCollection = '/addCollection';
  static const String collectionList = '/collectionList';
  static const String collectionTargetAndAchievement =
      '/collectionTargetAndAchievement';
  static const String cropSchedule = '/cropSchedule';
  static const String farmerregistration = '/farmerregistration';
  static const String expenseList = '/expenseList';
  static const String teamExpenseList = '/teamExpenseList';
  static const String salesTargetAndAchievement = '/salesTargetAndAchievement';
  static const String placeOrder = '/placeOrder';
  static const String salesReturn = '/salesReturn';

  static const String orderHistoy = '/orderHistoy';
  static const String dispatchHistoy = '/dispatchHistoy';
  static const String salesHistoy = '/salesHistoy';
  static const String farmerEdit = '/farmerEdit';
  static const String addExpense = '/addExpense';
  static const String dealrFollowUpAdd = '/dealrFollowUpAdd';
  static const String dealrFollowUpAddNew = '/dealrFollowUpAddNew';
  static const String dealerUpdate = '/dealerUpdate';
  static const String profile = '/profile';
  static const String productEnquiry = '/productEnquiry';
  static const String addStock = '/addStock';
  static const String selfcollectionTarget = '/selfcollectionTarget';

  static const String selfAssignTargetPointWise = '/selfAssignTargetPointWise';
  static const String quickReferance = '/quickReferance';
  static const String ai = '/ai';
  static const String growthReport = '/growthReport';

  static const String consultantDoctors = '/consultantDoctors';
  static const String consultantDoctorForm = '/consultantDoctorForm';
  static const String plantDoctor = '/plantDoctor';
  static const String schedule = '/schedule';
  static const String addPlot = '/addPlot';
  static const String scheduleList = '/scheduleList';
  static const String assignTask = '/assignTask';
  static const String assignTaskList = '/assignTaskList';

  static const String addFieldDayVisit = '/addFieldDayVisit';
  static const String addActivityNewDealerDistributor =
      '/addActivityNewDealerDistributor';
  static const String farmerCouponBooking = '/farmerCouponBooking';
  static const String jeepCampaning = '/jeepCampaning';
  static const String successStory = '/successStory';
  static const String dsiList = '/dsi';
  static const String addDsi = '/dsi/add';
  static const String fieldVisitForm = '/fieldVisitForm';
  static const String meetings = '/meetings';

  static const String complaintForm = '/complaintForm';

  static const String advertisement = '/advertisement';

  static final GoRouter router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: splash,

    routes: [
      GoRoute(
        path: meeting,
        name: 'meeting',
        builder: (context, state) => const MeetingPage(),
      ),
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) {
          return const SplashScreen();
        },
      ),

      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) {
          return const LoginScreen();
        },
      ),

      GoRoute(
        path: meetings,
        name: 'meetings',
        builder: (context, state) {
          return const MeetingPage();
        },
      ),

      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) {
          return const ProfilePage();
        },
      ),
      GoRoute(
        path: quickReferance,
        name: 'quickReferance',
        builder: (context, state) {
          return BlocProvider<quick_chart.GalleryBloc>(
            create: (_) => sl<quick_chart.GalleryBloc>(),
            child: const QuickReferencePage(),
          );
        },
      ),

      GoRoute(
        path: changePassword,
        name: 'changePassword',
        builder: (context, state) {
          return const ChangePassword();
        },
      ),

      GoRoute(
        path: '/plotmeasurement',
        name: 'plotmeasurement',
        builder: (context, state) => const PlotMeasurementPage(),
      ),
      GoRoute(
        path: addStock,
        name: 'addStock',
        builder: (context, state) {
          return const Dealerstocks();
        },
      ),

      GoRoute(
        path: selfcollectionTarget,
        name: 'selfcollectionTarget',
        builder: (context, state) {
          return const AssignSelfCollectionTargetPage();
        },
      ),

      GoRoute(
        path: noVisitDealer,
        name: 'notVisitDealer',
        builder: (context, state) {
          return const NotVisitedDealerPage();
        },
      ),

      GoRoute(
        path: addExpense,
        name: 'addExpense',
        builder: (context, state) {
          return const AddExpensePage();
        },
      ),

      GoRoute(
        path: orderHistoy,
        name: 'orderHistoy',
        builder: (context, state) {
          return const OrderHistoryPage();
        },
      ),
      GoRoute(
        path: dispatchHistoy,
        name: 'dispatchHistoy',
        builder: (context, state) {
          return const DispatchPage();
        },
      ),

      GoRoute(
        path: salesHistoy,
        name: 'salesHistoy',
        builder: (context, state) {
          return const SalesReturnHistoryPage();
        },
      ),

      GoRoute(
        path: gallery,
        name: 'gallery',
        builder: (context, state) {
          return const GalleryScreen();
        },
      ),

      GoRoute(
        path: scheme,
        name: 'scheme',
        builder: (context, state) {
          return const SchemeScreen();
        },
      ),

      GoRoute(
        path: AppRouter.assignTask,
        name: 'assignTask',
        builder: (context, state) {
          return BlocProvider<TaskBloc>(
            create: (_) => GetIt.instance<TaskBloc>(),
            child: const AssignTaskPage(),
          );
        },
      ),

      GoRoute(
        path: AppRouter.assignTaskList,
        name: 'assignTaskList',
        builder: (context, state) {
          return BlocProvider<AssignedTaskBloc>(
            create: (_) => GetIt.instance<AssignedTaskBloc>(),
            child: const AssignedTaskListPage(),
          );
        },
      ),

      GoRoute(
        path: farmerregistration,
        name: 'farmerregistration',
        builder: (context, state) {
          return const FarmerregistrationPage();
        },
      ),

      GoRoute(
        path: addActivityNewDealerDistributor,
        name: 'addActivityNewDealerDistributor',
        builder: (context, state) {
          return BlocProvider<DealerActivityBloc>(
            create: (_) => sl<DealerActivityBloc>(),
            child: const DealerActivityPage(),
          );
        },
      ),

      GoRoute(
        path: addFieldDayVisit,
        name: 'addFieldDayVisit',
        builder: (context, state) {
          return BlocProvider<FieldDayBloc>(
            create: (_) => sl<FieldDayBloc>(),
            child: const FieldDayPage(),
          );
        },
      ),

      GoRoute(
        path: farmerCouponBooking,
        name: 'farmerCouponBooking',
        builder: (context, state) {
          return BlocProvider<FarmerCouponBloc>(
            create: (_) => sl<FarmerCouponBloc>(),
            child: const FarmerCouponPage(),
          );
        },
      ),

      GoRoute(
        path: jeepCampaning,
        name: 'jeepCampaning',
        builder: (context, state) {
          return BlocProvider<JeepCampaignBloc>(
            create: (_) => sl<JeepCampaignBloc>(),
            child: const JeepCampaignPage(),
          );
        },
      ),

      GoRoute(
        path: successStory,
        name: 'successStory',
        builder: (context, state) {
          return BlocProvider<SuccessStoryBloc>(
            create: (_) => sl<SuccessStoryBloc>(),
            child: const SuccessStoryPage(),
          );
        },
      ),

      GoRoute(
        path: '/dsi',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => sl<DsiBloc>(),
            child: const DsiListPage(),
          );
        },
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) {
              return BlocProvider(
                create: (_) => sl<DsiBloc>(),
                child: const AddDsiPage(),
              );
            },
          ),
        ],
      ),

      GoRoute(
        path: fieldVisitForm,
        name: 'fieldVisitForm',
        builder: (context, state) {
          return BlocProvider<FieldVisitBloc>(
            create: (_) => sl<FieldVisitBloc>(),
            child: const FieldVisitPage(),
          );
        },
      ),

      GoRoute(
        path: complaintForm,
        name: 'complaintForm',
        builder: (context, state) {
          return BlocProvider<ComplaintBloc>(
            create: (_) => sl<ComplaintBloc>(),
            child: const ComplaintForm(),
          );
        },
      ),

      GoRoute(
        path: leaveList,
        name: 'leaveList',
        builder: (context, state) {
          return const LeaveListPage();
        },
      ),

      GoRoute(
        path: 'add-Leave',
        name: 'add-Leave',
        builder: (context, state) {
          return const AddLeavePage();
        },
      ),

      GoRoute(
        path: topTenDealer,
        name: 'topTenDealer',
        builder: (context, state) {
          return const TopTenDealerPage();
        },
      ),

      GoRoute(
        path: social,
        name: 'social',
        builder: (context, state) {
          return const SocialMediaPage();
        },
      ),

      GoRoute(
        path: teamLeaveList,
        name: 'teamLeaveList',
        builder: (context, state) {
          return const TeamLeaveListPage();
        },
      ),

      GoRoute(
        path: teamExpenseList,
        name: 'teamExpenseList',
        builder: (context, state) {
          return const TeamExpensePage();
        },
      ),

      GoRoute(
        path: addCollection,
        name: 'addCollection',
        builder: (context, state) {
          return const CollectionWiseFormPage();
        },
      ),

      GoRoute(
        path: selfAssignTargetPointWise,
        name: 'selfAssignTargetPointWise',
        builder: (context, state) {
          return const SelfTargetPage();
        },
      ),

      GoRoute(
        path: collectionList,
        name: 'collectionList',
        builder: (context, state) {
          return const CollectionListPage();
        },
      ),

      GoRoute(
        path: collectionTargetAndAchievement,
        name: 'collectionTargetAndAchievement',
        builder: (context, state) {
          return const DealerWiseTargetPage();
        },
      ),

      GoRoute(
        path: salesTargetAndAchievement,
        name: 'salesTargetAndAchievement',
        builder: (context, state) {
          return const SalesWiseTargetPage();
        },
      ),

      GoRoute(
        path: placeOrder,
        name: 'placeOrder',
        builder: (context, state) {
          return const PlaceOrderPage();
        },
      ),

      GoRoute(
        path: salesReturn,
        name: 'salesReturn',
        builder: (context, state) {
          return const SalesReturnPage();
        },
      ),

      GoRoute(
        path: cropSchedule,
        name: 'cropSchedule',
        builder: (context, state) {
          return const CropSchedulePage();
        },
      ),

      GoRoute(
        path: expenseList,
        name: 'expenseList',
        builder: (context, state) {
          return const MyExpensePage();
        },
      ),

      GoRoute(
        path: farmers,
        name: 'farmers',
        builder: (context, state) => const FarmerlistScreen(),
      ),
      GoRoute(
        path: farmerpin,
        name: 'farmerpin',
        builder: (context, state) {
          final farmerId = state.extra is String ? state.extra as String : '';
          return FamerFollowupPage(farmerId: farmerId);
        },
      ),

      GoRoute(
        path: productEnquiry,
        name: 'productEnquiry',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          final String productId = extra?['productId']?.toString() ?? '';

          final String productName = extra?['productName']?.toString() ?? '';

          return EnquiryPage(productId: productId, productName: productName);
        },
      ),

      GoRoute(
        path: dealerpin,
        name: 'dealerpin',
        builder: (context, state) {
          final dealerId = state.extra is String ? state.extra as String : '';
          final dealerName = state.extra is String ? state.extra as String : '';
          return DealerFollowupListPage(
            dealerId: dealerId,
            dealerName: dealerName,
          );
        },
      ),

      GoRoute(
        path: farmerEdit,
        name: 'farmerEdit',
        builder: (context, state) {
          final farmerDetails = state.extra is FarmerlistModel
              ? state.extra as FarmerlistModel
              : null;
          //  final farmerId = state.extra is String ? state.extra as String : '';
          return FarmerEditUpdateScren(farmerDetails: farmerDetails);
        },
      ),

      GoRoute(
        path: punch,
        name: 'punchIn',
        builder: (context, state) {
          final punchStat = state.extra is PunchStatEntity
              ? state.extra as PunchStatEntity
              : null;
          return PunchScreen(punchStat: punchStat);
        },
      ),

      GoRoute(
        path: punchOut,
        name: 'punchOut',
        builder: (context, state) {
          final punchStat = state.extra is PunchStatEntity
              ? state.extra as PunchStatEntity
              : null;
          return PunchOutScreen(punchStat);
        },
      ),
      GoRoute(
        path: lastPunchOut,
        name: 'lastPunchOut',
        builder: (context, state) {
          final punchStat = state.extra is PunchStatEntity
              ? state.extra as PunchStatEntity
              : null;
          return LastForceOutScreen(punchStat);
        },
      ),

      GoRoute(
        path: productList,
        name: 'productList',
        builder: (context, state) {
          final productList = state.extra is FertilizerCategoryEntity
              ? state.extra as FertilizerCategoryEntity
              : null;
          return ProductList(productList);
        },
      ),

      // ProductDetails
      GoRoute(
        path: productDetails,
        name: 'productDetails',
        builder: (context, state) {
          final productDetails = state.extra is FertilizerProductEntity
              ? state.extra as FertilizerProductEntity
              : null;
          return ProductDetails(productDetails);
        },
      ),

      GoRoute(
        path: empActivityReport,
        name: 'empActivityReport',
        builder: (context, state) {
          final String userId = state.extra is String
              ? state.extra as String
              : '';

          return MultiBlocProvider(
            providers: [
              BlocProvider<EmployeeActivityBloc>(
                create: (_) => sl<EmployeeActivityBloc>(),
              ),

              BlocProvider<EmployeeOutputBloc>(
                create: (_) => sl<EmployeeOutputBloc>(),
              ),
            ],

            child: EmployeeActivityReportPage(userId: userId),
          );
        },
      ),

      // CONSULTANT DOCTOR LIST
      GoRoute(
        path: AppRouter.consultantDoctors,
        name: 'consultantDoctors',
        builder: (context, state) {
          return BlocProvider<ConsultantBloc>(
            create: (_) => sl<ConsultantBloc>(),
            child: const ConsultantListPage(),
          );
        },
      ),

      GoRoute(
        path: AppRouter.plantDoctor,
        name: 'plantDoctor',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => sl<PlantDoctorBloc>(),
            child: const PlantDoctorPage(),
          );
        },
      ),

      GoRoute(
        path: AppRouter.scheduleList,
        name: 'scheduleList',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => sl<ScheduleListBloc>(),
            child: const ScheduleListPage(),
          );
        },
      ),

      GoRoute(
        path: AppRouter.schedule,
        name: 'schedule',
        builder: (context, state) {
          return BlocProvider(
            create: (_) => sl<FarmerScheduleBloc>(),
            child: const FarmerSchedulePage(),
          );
        },
      ),

      GoRoute(
        path: AppRouter.addPlot,
        name: 'plotRegistration',
        builder: (context, state) {
          final farmer = state.extra;
          if (farmer is! ScheduleFarmerEntity ||
              farmer.farmerId.trim().isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Plot registration')),
              body: const Center(
                child: Text('Please select a farmer from Schedule first.'),
              ),
            );
          }
          return BlocProvider<PlotBloc>(
            create: (_) => sl<PlotBloc>(),
            child: PlotRegistrationPage(farmer: farmer),
          );
        },
      ),
      // ADD / EDIT CONSULTANT DOCTOR
      // GoRoute(
      //   path: AppRouter.consultantDoctorForm,
      //   name: 'consultantDoctorForm',
      //   builder: (context, state) {
      //     final ConsultantDoctor? consultant = state.extra is ConsultantDoctor
      //         ? state.extra as ConsultantDoctor
      //         : null;

      //     return MultiBlocProvider(
      //       providers: [
      //         // CONSULTANT BLOC
      //         BlocProvider<ConsultantBloc>(create: (_) => sl<ConsultantBloc>()),

      //         // STATE / DISTRICT / TALUKA CUBIT
      //         BlocProvider<LocationCubit>(create: (_) => sl<LocationCubit>()),
      //       ],
      //       child: ConsultantFormPage(
      //         consultant: consultant,

      //         // Testing with the API's supplied user_id.
      //         userId: '4',
      //       ),
      //     );
      //   },
      // ),

      // ADD / EDIT CONSULTANT DOCTOR
      GoRoute(
        path: AppRouter.consultantDoctorForm,
        name: 'consultantDoctorForm',
        builder: (context, state) {
          final ConsultantDoctor? consultant = state.extra is ConsultantDoctor
              ? state.extra as ConsultantDoctor
              : null;

          return FutureBuilder<Map<String, dynamic>?>(
            future: SecureStorage.instance.getUserData(),
            builder: (context, snapshot) {
              // Loading user data
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Storage error
              if (snapshot.hasError) {
                return const Scaffold(
                  body: Center(child: Text('Unable to load user details')),
                );
              }

              // Get logged-in user data
              final userData = snapshot.data;

              final String userId = (userData?['user_id'] ?? '')
                  .toString()
                  .trim();

              debugPrint('CONSULTANT USER ID: $userId');

              // Check login
              if (userId.isEmpty || userId == '0') {
                return Scaffold(
                  appBar: AppBar(title: const Text('Consultant Doctor')),
                  body: const Center(
                    child: Text('Session expired. Please login again.'),
                  ),
                );
              }

              // Open consultant form
              return MultiBlocProvider(
                providers: [
                  BlocProvider<ConsultantBloc>(
                    create: (_) => sl<ConsultantBloc>(),
                  ),

                  BlocProvider<LocationCubit>(
                    create: (_) => sl<LocationCubit>(),
                  ),
                ],
                child: ConsultantFormPage(
                  consultant: consultant,
                  userId: userId, // Dynamic logged-in user ID
                ),
              );
            },
          );
        },
      ),

      GoRoute(
        path: monthlyPerformanceReport,
        name: 'monthlyPerformanceReport',
        builder: (context, state) {
          final String userId = state.extra is String
              ? state.extra as String
              : '';

          return MultiBlocProvider(
            providers: [
              BlocProvider<MonthlyPerformanceBloc>(
                create: (_) => sl<MonthlyPerformanceBloc>(),
              ),

              BlocProvider<EmployeeOutputBloc>(
                create: (_) => sl<EmployeeOutputBloc>(),
              ),
            ],
            child: const MonthlyPerformanceReportPage(),
          );
        },
      ),

      GoRoute(
        path: monthlyVisitPerformanceReport,
        name: 'monthlyVisitPerformanceReport',
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<VisitMonthWiseBloc>(
                create: (_) => sl<VisitMonthWiseBloc>(),
              ),
            ],
            child: const VisitMonthWiseReportPage(),
          );
        },
      ),

      GoRoute(
        path: growthReport,
        name: 'growthReport',
        builder: (context, state) {
          return BlocProvider<GrowthReportBloc>(
            create: (_) => sl<GrowthReportBloc>(),
            child: const GrowthReportPage(),
          );
        },
      ),

      GoRoute(
        path: calendarReport,
        name: 'calendarReport',
        builder: (context, state) {
          return BlocProvider<CalendarReportBloc>(
            create: (_) => sl<CalendarReportBloc>(),
            child: const CalendarReportPage(),
          );
        },
      ),

      GoRoute(
        path: dealrFollowUpAdd,
        name: 'dealrFollowUpAdd',
        builder: (context, state) {
          return DealerFollowupAdd();
        },
      ),
      GoRoute(
        path: dealrFollowUpAddNew,
        name: 'dealrFollowUpAddNew',
        builder: (context, state) {
          final dealerId = state.extra is String ? state.extra as String : '';
          final dealerName = state.extra is String ? state.extra as String : '';
          return AddDealerVisitPage(dealerId: dealerId, dealerName: dealerName);
        },
      ),

      GoRoute(
        path: dealerUpdate,
        name: 'dealerUpdate',
        builder: (context, state) {
          final dealerDetails = state.extra is DealerListModel
              ? state.extra as DealerListModel
              : null;
          return EditUpdateDealer(dealerDetails);
        },
      ),

      GoRoute(
        path: empOutputReport,
        name: 'empOutputReport',
        builder: (context, state) {
          final userId = state.extra is String ? state.extra as String : '';

          return BlocProvider<EmployeeOutputBloc>(
            create: (_) => sl<EmployeeOutputBloc>(),
            child: EmployeeOutputReportPage(userId: userId),
          );
        },
      ),

      GoRoute(
        path: visitSummaryReport,
        name: 'visitSummaryReport',
        builder: (context, state) {
          final String userId = state.extra is String
              ? state.extra as String
              : '';

          return MultiBlocProvider(
            providers: [
              BlocProvider<VisitReportBloc>(
                create: (_) => sl<VisitReportBloc>(),
              ),

              BlocProvider<EmployeeOutputBloc>(
                create: (_) => sl<EmployeeOutputBloc>(),
              ),
            ],

            child: VisitSummaryPage(userId: userId),
          );
        },
      ),

      GoRoute(
        path: aboutUs,
        name: 'aboutUs',
        builder: (context, state) {
          return const AboutUsPage();
        },
      ),

      GoRoute(
        path: visits,
        name: 'visits',
        builder: (context, state) {
          return const DealerListScreen();
        },
      ),

      GoRoute(
        path: contactUs,
        name: 'contactUs',
        builder: (context, state) {
          return const ContactUsPage();
        },
      ),

      GoRoute(
        path: userGuide,
        name: 'userGuide',
        builder: (context, state) {
          return const UserGuidelinesPage();
        },
      ),

      GoRoute(
        path: notification,
        name: 'notification',
        builder: (context, state) {
          final userId = state.extra is String
              ? int.tryParse(state.extra as String) ?? 0
              : state.extra is int
              ? state.extra as int
              : 0;

          return NotificationPage(userId: userId, isLogin: true, userType: '');
        },
      ),

      GoRoute(
        path: ai,
        name: 'ai',
        builder: (context, state) => BlocProvider<AiBloc>(
          create: (_) => sl<AiBloc>(),
          child: const AiChatbot(),
        ),
      ),

      GoRoute(
        path: advertisement,
        name: 'advertisement',
        builder: (context, state) {
          return BlocProvider<QuickAcessBloc>(
            create: (_) => sl<QuickAcessBloc>(),
            child: const Advertisement(),
          );
        },
      ),


      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },

        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: home,
                name: 'home',
                builder: (context, state) {
                  return const Home();
                },
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: followup,
                name: 'followup',
                builder: (context, state) {
                  return const FollowupPage();
                },
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: reportPage,
                name: 'reportPage',
                builder: (context, state) {
                  return const ReportsHomePage();
                },
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: products,
                name: 'products',
                builder: (context, state) {
                  return const ProductCategoryScreen();
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
