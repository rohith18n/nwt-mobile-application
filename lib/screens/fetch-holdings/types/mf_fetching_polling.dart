class MfFetchingPolling {
    int statusCode;
    String message;
    Data? data;
    bool ismffetched;

    MfFetchingPolling({
        required this.statusCode,
        required this.message,
        required this.data,
        required this.ismffetched,
    });

    factory MfFetchingPolling.fromJson(Map<String, dynamic> json) => MfFetchingPolling(
        statusCode: json["statusCode"],
        message: json["message"],
        data: json["data"] != null ? Data.fromJson(json["data"]) : null,
        ismffetched: json["ismffetched"],
    );

    Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "message": message,
        "data": data?.toJson(),
        "ismffetched": ismffetched,
    };
}

class Data {
    AnalyzingPortfolio otp;
    AnalyzingPortfolio mfcConnect;
    AnalyzingPortfolio fetchingData;
    AnalyzingPortfolio processingData;
    AnalyzingPortfolio analyzingPortfolio;

    Data({
        required this.otp,
        required this.mfcConnect,
        required this.fetchingData,
        required this.processingData,
        required this.analyzingPortfolio,
    });

    factory Data.fromJson(Map<String, dynamic> json) => Data(
        otp: AnalyzingPortfolio.fromJson(json["otp"]),
        mfcConnect: AnalyzingPortfolio.fromJson(json["mfc_connect"]),
        fetchingData: AnalyzingPortfolio.fromJson(json["fetching_data"]),
        processingData: AnalyzingPortfolio.fromJson(json["processing_data"]),
        analyzingPortfolio: AnalyzingPortfolio.fromJson(json["analyzing_portfolio"]),
    );

    Map<String, dynamic> toJson() => {
        "otp": otp.toJson(),
        "mfc_connect": mfcConnect.toJson(),
        "fetching_data": fetchingData.toJson(),
        "processing_data": processingData.toJson(),
        "analyzing_portfolio": analyzingPortfolio.toJson(),
    };
}

class AnalyzingPortfolio {
    String status;
    String message;

    AnalyzingPortfolio({
        required this.status,
        required this.message,
    });

    factory AnalyzingPortfolio.fromJson(Map<String, dynamic> json) => AnalyzingPortfolio(
        status: json["status"],
        message: json["message"],
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
    };
}
