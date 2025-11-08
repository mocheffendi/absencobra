class FaceApiResponse {
  final double? percent;
  final String? message;
  final String? response;
  final String? error;

  FaceApiResponse({this.percent, this.message, this.response, this.error});

  factory FaceApiResponse.fromJson(Map<String, dynamic> json) {
    return FaceApiResponse(
      percent: json['percent'] as double?,
      message: json['message'] as String?,
      response: json['response'] as String?,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'percent': percent,
      'message': message,
      'response': response,
      'error': error,
    };
  }
}
