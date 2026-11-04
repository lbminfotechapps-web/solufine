class ApiClient {
  //=========================== For Live ===================================================================================
  static const String baseUrl =
      "https://agroaicrm.com/solufine_agritech/mobileapi/Mobile_app_for_businessplus_kotlin_new";
  static const String imageBaseUrl =
      "https://agroaicrm.com/solufine_agritech/uploads/";

  static const String dsiImageBaseUrl = '${imageBaseUrl}dsi_img/';
  static const String imageGalleryUrl =
      "https://agroaicrm.com/solufine_agritech/uploads/gallery/";
  static const String imageCropscheduleUrl =
      "https://agroaicrm.com/solufine_agritech/uploads/crop_schedule/";
  static const String imageEmployeeActivityReportUrl =
      "https://agroaicrm.com/solufine_agritech/uploads/selfie/";
  static const String imageExpensetUrl =
      "https://agroaicrm.com/solufine_agritech/uploads/Expense_Images/";

  static const String baseUrlForAssignTask =
      'https://agroaicrm.com/solufine_agritech/uploads/Task_img/';

  //  //=========================== For Local ===================================================================================
  //   static const String baseUrl ="http://192.168.1.253:85/solufine_agritech/mobileapi/Mobile_app_for_businessplus_kotlin_new";
  //   static const String imageBaseUrl ="http://192.168.1.253:85/solufine_agritech/uploads/";
  //   static const String imageGalleryUrl ="http://192.168.1.253:85/solufine_agritech/uploads/gallery/";
  //   static const String imageCropscheduleUrl ="http://192.168.1.253:85/solufine_agritech/uploads/crop_schedule/";
  //   static const String imageEmployeeActivityReportUrl ="http://192.168.1.253:85/solufine_agritech/uploads/selfie/";
  //   static const String imageExpensetUrl ="http://192.168.1.253:85/solufine_agritech/uploads/Expense_Images/";

  static const String login = "/user_login";
  static const String getLastThirtyNotVisited = "/getLastThiertyNotVisited";
  static const String getNearByOutlets = "/getNearByOutlets";
  static const String userMenu = "/getUserMenu_new";
  static const String punchStatus = "/getLastTransactionInOutStatus";
  static const String getEmployeeActivityDetails =
      '/getEmployeeActivityDetails_new';

  static const String getVisitReportDetails = "/getVisitReportDetails";
  static const String getEmployeeOutputReport = "/getEmployeeOutputReport";

  static const String getEmpOutputDetail = "/getEmpOutputDetail";
  static const String getEmployees = "/getAssignedEmployees";
  static const String organizationDetails = "/getOrganizationDetails";
  static const String getNotificationList = "/getNotificationList";

  static const String getMyLeaveList = "/getMyLeaveList";
  static const String addLeave = "/addLeave";
  static const String punchAddInOut = "/add_in_out_details";
  static const String getVehicleType = "/getVehicleType";
  static const String getGalleryDetails = "/getGalleryDetails";
  static const String getSchemedetails = "/getSchemes";
  static const String getTopTenDealerVisit = "/getHighestTopDealer";
  static const String getSocialMedia = "/getSocialMedia";
  static const String getMyEmployeeLeaveList = "/getMyEmployeeLeaveList";
  static const String updateLeaveStatus = "/updateLeaveStatus";
  static const String visitCountgraph = "/getEmployeevisitcount";
  static const String getState = "/get_state";
  static const String submitPaymentDetails = "/submitPaymentDetails";

  static const String getBankDetails = "/getBankDetails";
  static const String getTalukaWiseOutletForOrderNew =
      "/getTalukaWiseOutletForOrderNew";
  static const String getCategoryproductDetails =
      "/get_category_product_details";

  static const String getProductName = "/get_product_name";
  static const String getCollectionList = "/getCollectionList";
  static const String getCollectionWiseTarget = '/getCollectionWiseTarget';

  static const String getTargetDates = '/getTargetDates';
  static const String getCropsSchedule = '/getCropsSchedule';

  static const String getMyExpensesList = '/getMyExpensesList';
  static const String getMyEmployeeExpensesList = '/getMyEmployeeExpensesList';
  static const String update_expenses = '/update_expenses';

  static const String getEmployeeVisitCount = '$baseUrl/getVisitCount';
  static const String getDistrictTaluka = '/get_district_taluka';
  static const String getCropAndIrigationDetails =
      '/getCropAndIrigationDetails';

  static const String addFarmerDetails = '/add_farmer_details';
  static const String updateFarmerDtails = '/update_farmer_details';
  static const String getDispatchList = '/getDispatchDetails';
  static const String remark_list = "/remark_list";
  static const String add_remark = "/add_remark";
  static const String getdealervisitpurpose = "/getdealervisitpurpose";
  static const String getInpunchPending = '/getPendingInpunchStatus';
  static const String getOrderHistory = '/getOrderList';

  static const String getGodown = "/get_godown";
  static const String getCategory = "/getCategory";
  static const String getCatgoryProducts = "/getCatgoryProducts";
  static const String placeOrder = "/placeOrder";
  static const String submitSalesReturnRequest = "/submitSalesReturnRequest";

  static const String getProductDetailRatesKvat = "/getProductDetailRatesKvat";
  static const String getEmployeeStatus = '/getEmployeeStatus';

  static const String updateOrderStatus = '/updateOrderStatus';

  static const String salesReturnHistory = '/getSalesReturnDetails';
  static const String getSalesTargetDates = '/getSalesTargetDates';

  static const String getDealerName = '/getTalukaWiseOutletForOrderNew';

  // static const String getSalesWiseTarget = '/getSalesWiseTarget';
  static const String getSalesWiseGroupTarget = '/getSalesWiseGroupTarget';

  static const String getExpenseParameters = '/getExpenseParameters';

  static const String getDAAmount = '/getDAAmount';
  static const String getExpensesStatus = '/getExpensesStatus';
  static const String addExpenseDetails = '/add_expense_details';

  static const String upload_sign = "/upload_sign";

  static const String addDealerFollowUp = '/pin_location';
  static const String updateDealerFollowUp = '/update_pin_location';
  static const String famerCallApi = '/submitCallingDetails';
  static const String upcomingNextFollowup = "/upcoming_next_followup";

  static const String submitEnquiryDetails = '/submit_enquiry_details';
  static const String trackLocationStore = '/addLocation';

  static const String addDealerLocation = '/addExistingDealerLocation';

  static const String getProductDetail = '/getProductDetail';
  static const String addStock = '/addStock';

  static const String getDealerForSalesTarget = '/getDealerForSalesTarget';

  static const String get_collection_type = '/get_collection_type';
  static const String addMonthlyCollection = '/add_monthly_collection';
  static const String getProductGroup = '/get_product_group';
  static const String getGroupWiseAchievementPoint =
      '/getGroupWiseAchievementPoint';
  static const String add_group_sales_target = '/add_group_sales_target';
  static const String getCollectionType = '/get_collection_type';

  static const String changePassword = '/changePassword';

  static const String getReportFinancialYears = '/getReportFinancialYears';
  // Replace this with your real monthly report endpoint
  static const String getMonthlyPerformance = '/getReportStatMonthlyDetails';
  static const String getDailyPerformance = '/getStatDailyDetails';
  static const String getHourlyPerformance = '/getStatHourlyDetails';
  static const String getAreaPerformance = '/getStatAreaDetails';
  static const String getTopDealers = '/getStatTopDealers';
  static const String getExpensePerformance = '/getStatExpenseDetails';
  static const String getGrowthReport = '/getGrowthReport';

  static const String getApplicationPhase = '/get_application_phase';
  static const String getVisitMonthWise = '/getVisitMonthWise';
  static const String getVisitDayWise = '/getVisitDayWise';
  static const String getVisitHourWise = '/getVisitHourWise';
  static const String getVisitFrequency = '/getVisitFrequency';
  static const String getVisitGeoWise = '$baseUrl/getVisitGeoWise';
  static const String getVisitTopList = '/getVisitTopList';
  static const String getVisitTopEmployee = '/getVisitTopEmployee';

  static const String askAiQuery = '/askAiQuery';
  static const String getFollowupCalendar = '/get_followup_calendar';
  static const String addDoctor = '/addDoctor';
  static const String getDoctorList = '/get_doctor_list';

  static const String getCropList = '/getCropList';
  static const String getScheduleFarmerList = '/getFarmerList';

  // IMPORTANT:
  // Replace this with the exact endpoint from your old ApiService.java.
  static const String getPlantRecommendedProducts = '/getMicronutrients';

  static const String getPlotFarmers = '/getFarmerList';
  static const String getFarmerPlots = '/getFarmerPlots';
  static const String submitPlotRegistration = '/addPlot';
  static const String addSchedule = '/addSchedule';
  static const String getScheduleList = '/getScheduleList';
  static const String deleteSchedule = '/deleteSchedule';

  static const String getPlotwiseScheduleList = '/getPlotwiseScheduleList';
  static const String updateSchedule = '/updateSchedule';
  static const String getProductListForSchedule = '/getProductListForSchedule';
  static const String addTask = '/add_task';
  static const String createdTaskList = '/created_task_list';
  static const String updateTaskStatus = '/updateTaskStatus';
  static const String assignedTaskList = '/assigned_task_list';
  static const String submitDealerDistributor = '/submitDealerDistributor';
  static const String submitFieldDayProgram = '/submitFieldDayProgram';
  static const String submitFarmerCoupon = '/submitFarmerCoupon';
  static const String getSeason = '/getSeason';
  static const String submitJeepCampaining = '/submitJeepCampaining';
  static const String submitSuccessStory = '/submitDealerDistributor';
  static const String successStoryCrops = '/getCropAndIrigationDetails';
  static const String dsiList = '/dsi_list';
  static const String addDsi = '/add_dsi';
  static const String insertFieldVisitForm = '/insertFieldVisitForm';

  static const String getMeetingBudgetApprovalReceivedFrom = '/getMeetingBudgetApprovalReceivedFrom';
  static const String submitFarmerMeetingDetails = '/submitFarmerMeetingDetails';
  static const String submitComplaintForm = '/submitComplaintForm';
  static const String getDealerRetailerList = '/getDealerRetailerList';
  static const String getCropRecords = '/getCropRecords';
    static const String getClassRecords = '/getClassRecords';
     static const String getVarietyRecords = '/getVarietyRecords';

        static const String getMonthlyPerformanceList = '/getMonthlyPerformanceList';

         static const String getMonthlyPerformanceListwithImage = '/getMonthlyPerformanceListwithImage';
           static const String getAdvertisement = '/getAdvertisement';
}


