import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nwt_app/constants/colors.dart';
import 'package:nwt_app/constants/sizing.dart';
import 'package:nwt_app/controllers/user_controller.dart';
import 'package:nwt_app/screens/financial_profiling/types/financial_profiling.dart';
import 'package:nwt_app/screens/financial_profiling/types/financial_profiling_question_response.dart';
import 'package:nwt_app/services/financial_profiling/financial_profiling.dart';
import 'package:nwt_app/services/financial_profiling/financial_profiling_answers.dart';
import 'package:nwt_app/services/financial_profiling/submit_financial_profiling.dart';
import 'package:nwt_app/services/financial_profiling/update_financial_profiling.dart';
import 'package:nwt_app/widgets/common/button_widget.dart';
import 'package:nwt_app/widgets/common/text_widget.dart';
import 'package:nwt_app/widgets/common/whatsapp_support_button.dart';

class FinancialProfiling extends StatefulWidget {
  const FinancialProfiling({super.key, required this.isUserAnswered});

  final bool isUserAnswered;

  @override
  State<FinancialProfiling> createState() => _FinancialProfilingState();
}

class _FinancialProfilingState extends State<FinancialProfiling>
    with SingleTickerProviderStateMixin {
  // Service instances
  final FinancialProfilingService _service = FinancialProfilingService();
  final FinancialProfilingAnswersService _answersService =
      FinancialProfilingAnswersService();
  final SubmitFinancialProfilingService _submitService =
      SubmitFinancialProfilingService();
  final UpdateFinancialProfilingService _updateService =
      UpdateFinancialProfilingService();

  // User controller for updating user data after successful submission
  final UserController _userController = Get.find<UserController>();

  // Animation controller for page transitions
  late AnimationController _animationController;
  late PageController _pageController;

  // API data
  List<Datum>? _questions;
  List<FinancialProfilingQuestionData>? _questionsWithAnswers;
  bool _isLoading = false;

  // Current question index
  int _currentQuestionIndex = 0;

  // Total number of questions (will be updated from API)
  int _totalQuestions = 0;

  // Map to store answers by question ID
  final Map<int, dynamic> _selectedAnswers = {};

  // State management for answered mode
  bool _isEditingQuestion = false;
  int? _editingQuestionIndex;
  bool _isSubmissionSuccessful = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Initialize page controller
    _pageController = PageController();

    // Fetch data based on user answered state
    if (widget.isUserAnswered) {
      _fetchQuestionsWithAnswers();
    } else {
      _fetchQuestions();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Fetch questions from API
  Future<void> _fetchQuestions() async {
    await _service
        .getFinancialProfilingQuestions(
          onLoading: (isLoading) {
            setState(() {
              _isLoading = isLoading;
            });
          },
        )
        .then((response) {
          setState(() {
            _questions = response.data;
            _totalQuestions = response.data.length;
          });
        });
  }

  // Fetch questions with user answers from API
  Future<void> _fetchQuestionsWithAnswers() async {
    await _answersService
        .getFinancialProfilingAnswers(
          onLoading: (isLoading) {
            setState(() {
              _isLoading = isLoading;
            });
          },
        )
        .then((response) {
          setState(() {
            _questionsWithAnswers = response.data;
            _totalQuestions = response.data.length;

            // Populate selected answers from the response
            _populateSelectedAnswers();
          });
        });
  }

  // Populate selected answers from the API response
  void _populateSelectedAnswers() {
    if (_questionsWithAnswers == null) return;

    for (final questionData in _questionsWithAnswers!) {
      final questionId = questionData.id;
      final answer = questionData.answer;

      // Handle different question types
      switch (questionData.type) {
        case QuestionType.SINGLE:
          // For single select, find the option value from selected option IDs
          if (answer.selectedoptionids.isNotEmpty) {
            final selectedOptionId = answer.selectedoptionids.first;
            final selectedOption = questionData.options.firstWhere(
              (option) => option.id == selectedOptionId,
              orElse: () => questionData.options.first,
            );
            _selectedAnswers[questionId] = selectedOption.optionvalue;
          }
          break;

        case QuestionType.MULTI:
          // For multi select, get all selected option values
          List<String> selectedValues = [];
          for (final optionId in answer.selectedoptionids) {
            final option = questionData.options.firstWhere(
              (option) => option.id == optionId,
              orElse: () => questionData.options.first,
            );
            selectedValues.add(option.optionvalue);
          }
          _selectedAnswers[questionId] = selectedValues;
          break;

        case QuestionType.RANGE:
          // For range questions, parse the answer text as double
          try {
            _selectedAnswers[questionId] = double.parse(answer.answertext);
          } catch (e) {
            _selectedAnswers[questionId] = 0.0;
          }
          break;
      }
    }
  }

  // Get current question
  Datum? get _currentQuestion {
    if (_isEditingQuestion &&
        _questionsWithAnswers != null &&
        _editingQuestionIndex != null) {
      // Return the question being edited from questionsWithAnswers
      if (_editingQuestionIndex! < _questionsWithAnswers!.length) {
        final questionData = _questionsWithAnswers![_editingQuestionIndex!];
        // Convert FinancialProfilingQuestionData to Datum for compatibility
        return Datum(
          id: questionData.id,
          questiontext: questionData.questiontext,
          subtitle: questionData.subtitle,
          category: questionData.category,
          type: _convertQuestionType(questionData.type),
          options:
              questionData.options
                  .map(
                    (option) => Option(
                      id: option.id,
                      optiontext: option.optiontext,
                      optionvalue: option.optionvalue,
                      displayorder: option.displayorder,
                    ),
                  )
                  .toList(),
        );
      }
    }

    return _questions != null && _questions!.length > _currentQuestionIndex
        ? _questions![_currentQuestionIndex]
        : null;
  }

  // Convert QuestionType to Type for compatibility
  Type _convertQuestionType(QuestionType questionType) {
    switch (questionType) {
      case QuestionType.SINGLE:
        return Type.SINGLE;
      case QuestionType.MULTI:
        return Type.MULTI;
      case QuestionType.RANGE:
        return Type.RANGE;
    }
  }

  // Start editing a specific question
  void _startEditingQuestion(int questionIndex) {
    setState(() {
      _isEditingQuestion = true;
      _editingQuestionIndex = questionIndex;
      _currentQuestionIndex =
          0; // Reset to show the single question being edited
    });
  }

  // Cancel editing and return to summary view
  void _cancelEditing() {
    setState(() {
      _isEditingQuestion = false;
      _editingQuestionIndex = null;
      _currentQuestionIndex = 0;
    });
  }

  // Save the edited question and return to summary
  void _saveEditedQuestion() async {
    if (_editingQuestionIndex == null || _questionsWithAnswers == null) return;

    final currentQuestion = _questionsWithAnswers![_editingQuestionIndex!];
    final questionId = currentQuestion.id;

    // Get the selected answer for this question
    final selectedAnswer = _selectedAnswers[questionId];
    if (selectedAnswer == null) return;

    // Prepare the answer data based on question type
    String answerText = '';
    List<int>? selectedOptionIds;

    if (currentQuestion.type == QuestionType.SINGLE) {
      // For single select, selectedAnswer is the option value (String)
      final selectedOptionValue = selectedAnswer.toString();

      // Find the option by its value to get the ID
      final selectedOption = currentQuestion.options.firstWhere(
        (option) => option.optionvalue == selectedOptionValue,
        orElse: () => currentQuestion.options.first,
      );

      answerText = selectedOption.optiontext;
      selectedOptionIds = [selectedOption.id];
    } else if (currentQuestion.type == QuestionType.MULTI) {
      // For multi select, selectedAnswer is a list of option values (List<String>)
      List<String> selectedOptionValues = [];
      if (selectedAnswer is List<String>) {
        selectedOptionValues = selectedAnswer;
      } else if (selectedAnswer is List) {
        selectedOptionValues =
            selectedAnswer.map((item) => item.toString()).toList();
      }

      // Find options by their values to get the IDs
      final selectedOptions =
          currentQuestion.options
              .where(
                (option) => selectedOptionValues.contains(option.optionvalue),
              )
              .toList();

      selectedOptionIds = selectedOptions.map((option) => option.id).toList();
      answerText = selectedOptions
          .map((option) => option.optiontext)
          .join(', ');
    } else if (currentQuestion.type == QuestionType.RANGE) {
      // For range, selectedAnswer is the numeric value
      answerText = selectedAnswer.toString();
      selectedOptionIds = null; // Range questions don't have option IDs
    }

    // Create the answer object
    final answer = FinancialProfilingAnswer(
      questionid: questionId,
      answertext: answerText,
      selectedoptionids: selectedOptionIds,
    );

    // Call the update service
    try {
      final response = await _updateService.updateFinancialProfilingAnswers(
        answers: [answer],
        onLoading: (isLoading) {
          setState(() {
            _isLoading = isLoading;
          });
        },
      );

      if (response.statusCode == 200) {
        // Update successful - refresh the data and return to summary
        await _fetchQuestionsWithAnswers();
        _cancelEditing();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // Placeholder for any additional properties if needed

  // Show confirmation dialog before leaving the screen
  Future<bool> _confirmExit() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCardBG,
        title: const Text(
          'Leave Finance Profiling?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to leave Finance Profiling?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('NO', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('YES', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  // Get current question title
  String get _currentQuestionTitle {
    if (_currentQuestion == null) {
      return "Question ${_currentQuestionIndex + 1}";
    }
    return _currentQuestion!.questiontext;
  }

  // Get current section title
  String get _currentSectionTitle {
    if (_currentQuestion == null) return "Financial Profile:";
    return "${_currentQuestion!.category}:";
  }

  // Get current section description
  String get _currentSectionDescription {
    if (_currentQuestion == null) {
      return "Please provide the following information to complete your profile.";
    }
    return _currentQuestion!.subtitle;
  }

  // Submit answers to the API
  Future<void> _submitAnswers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Format answers for submission
      List<Map<String, dynamic>> formattedAnswers = [];

      // Process each answer based on question type
      _selectedAnswers.forEach((questionId, value) {
        // Find the question to determine its type
        final question = _questions?.firstWhere(
          (q) => q.id == questionId,
          orElse:
              () => _questions!.first, // Default to first question if not found
        );

        if (question != null) {
          Map<String, dynamic> answer = {'questionid': questionId};

          switch (question.type) {
            case Type.SINGLE:
              // Find the option ID and text for the selected value
              try {
                final option = question.options.firstWhere(
                  (o) => o.optionvalue == value,
                );
                // Use option text as answertext
                answer['answertext'] = option.optiontext;
                answer['selectedoptionids'] = [option.id];
              } catch (e) {
                // If option not found, use the raw value
                answer['answertext'] = value.toString();
              }
              break;

            case Type.MULTI:
              final List<String> selectedValues = value as List<String>;
              List<int> optionIds = [];
              List<String> optionTexts = [];

              // Find option IDs and texts for selected values
              for (String optionValue in selectedValues) {
                try {
                  final option = question.options.firstWhere(
                    (o) => o.optionvalue == optionValue,
                  );
                  optionIds.add(option.id);
                  optionTexts.add(option.optiontext);
                } catch (e) {
                  // Skip this option if not found
                }
              }

              // For multi choice, join the option texts with comma
              answer['answertext'] = optionTexts.join(', ');

              answer['selectedoptionids'] = optionIds;
              break;

            case Type.RANGE:
              // For range questions, convert the value to string
              answer['answertext'] = value.toString();
              break;
          }

          formattedAnswers.add(answer);
        }
      });

      // Submit answers to API
      final result = await _submitService.submitFinancialProfiling(
        answers: formattedAnswers,
        onLoading: (isLoading) {
          if (mounted) {
            setState(() {
              _isLoading = isLoading;
            });
          }
        },
      );

      // Handle response
      if (result['success'] == true) {
        // Show success screen
        if (mounted) {
          setState(() {
            _isSubmissionSuccessful = true;
          });
        }
      }
    } catch (e) {
      // Handle any exceptions
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Check if any option is selected
  bool get _isAnyOptionSelected {
    if (_currentQuestion == null) return false;

    final questionId = _currentQuestion!.id;
    final answer = _selectedAnswers[questionId];

    if (answer == null) return false;

    switch (_currentQuestion!.type) {
      case Type.SINGLE:
        return true; // If any option is selected, it's valid
      case Type.MULTI:
        return (answer as List<String>).isNotEmpty;
      case Type.RANGE:
        return (answer as double) > 0;
    }
  }

  // Handle option selection
  void _handleOptionSelection(Option option) {
    if (_currentQuestion == null) return;

    final questionId = _currentQuestion!.id;

    setState(() {
      switch (_currentQuestion!.type) {
        case Type.SINGLE:
          _selectedAnswers[questionId] = option.optionvalue;
          break;
        case Type.MULTI:
          final List<String> selectedOptions =
              (_selectedAnswers[questionId] as List<String>?) ?? [];

          if (selectedOptions.contains(option.optionvalue)) {
            selectedOptions.remove(option.optionvalue);
          } else {
            selectedOptions.add(option.optionvalue);
          }

          _selectedAnswers[questionId] = selectedOptions;
          break;
        default:
          break;
      }
    });
  }

  // Handle range value change
  void _handleRangeValueChange(double value) {
    if (_currentQuestion == null) return;

    final questionId = _currentQuestion!.id;

    setState(() {
      _selectedAnswers[questionId] = value;
    });
  }

  // Build a simplified range selector UI for any range question
  Widget _buildRangeSelector() {
    if (_currentQuestion == null) return const SizedBox.shrink();

    final questionId = _currentQuestion!.id;
    final currentValue = (_selectedAnswers[questionId] as double?) ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern gradient slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.green,
            inactiveTrackColor: Colors.grey.shade800,
            thumbColor: Colors.white,
            overlayColor: Colors.green.withOpacity(0.3),
            valueIndicatorColor: Colors.green,
            valueIndicatorTextStyle: const TextStyle(color: Colors.white),
            trackHeight: 8,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
          ),
          child: Slider(
            value: currentValue,
            min: 0,
            max: 100,
            divisions: 100,
            label: "${currentValue.toInt()}%",
            onChanged: (value) {
              _handleRangeValueChange(value);
            },
          ),
        ),

        // Add spacer at the bottom
        const SizedBox(height: 100),
      ],
    );
  }

  // Get current options list
  List<Option> get _currentOptions {
    if (_currentQuestion == null) return [];
    return _currentQuestion!.options;
  }

  // Build summary view for answered questions
  Widget _buildSummaryView() {
    if (_questionsWithAnswers == null || _questionsWithAnswers!.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizing.scaffoldHorizontalPadding,
      ),
      itemCount: _questionsWithAnswers!.length,
      itemBuilder: (context, index) {
        final questionData = _questionsWithAnswers![index];
        final answer = questionData.answer;

        // Get answer text based on question type
        String answerText = '';
        if (answer.selectedoptionids.isNotEmpty) {
          List<String> selectedTexts = [];
          for (final optionId in answer.selectedoptionids) {
            final option = questionData.options.firstWhere(
              (option) => option.id == optionId,
              orElse: () => questionData.options.first,
            );
            selectedTexts.add(option.optiontext);
          }
          answerText = selectedTexts.join(', ');
        } else if (answer.answertext.isNotEmpty) {
          answerText = answer.answertext;

          // Add percentage symbol for range questions
          if (questionData.type == QuestionType.RANGE) {
            // Check if the answer is a numeric value
            final numericValue = double.tryParse(answerText);
            if (numericValue != null) {
              // Format as integer if it's a whole number, otherwise keep decimal
              if (numericValue == numericValue.toInt()) {
                answerText = '${numericValue.toInt()}%';
              } else {
                answerText = '$numericValue%';
              }
            }
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.darkCardBG,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question header with edit button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              questionData.questiontext,
                              variant: AppTextVariant.bodyLarge,
                              weight: AppTextWeight.semiBold,
                              lineHeight: 1.4,
                            ),
                          ],
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'Edit ${questionData.questiontext}',
                        onTap: () => _startEditingQuestion(index),
                        child: GestureDetector(
                          onTap: () => _startEditingQuestion(index),
                          child: const Icon(
                            Icons.border_color_outlined,
                            size: 16,
                            color: AppColors.darkPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Answer section
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        AppText(
                          answerText.isNotEmpty
                              ? answerText
                              : 'No answer provided',
                          variant: AppTextVariant.bodyMedium,
                          weight: AppTextWeight.medium,
                          colorType: AppTextColorType.secondary,
                          // lineHeight: 1.3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build success screen after form submission
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success icon
              ExcludeSemantics(
                child: SizedBox(
                  height: 200.h,
                  width: 200.w,
                  child: Lottie.asset(
                    'assets/lottie/successful.json',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              SizedBox(height: 40.h),

              // Success message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      // height: 1.2,
                      fontFamily: 'Montserrat',
                    ),
                    children: [
                      TextSpan(text: 'Your '),
                      TextSpan(
                        text: 'Financial\nProfiling',
                        style: TextStyle(color: AppColors.linkColor),
                      ),
                      TextSpan(text: ' is\nSuccessfully Done!'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizing.scaffoldHorizontalPadding,
        ),
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Continue',
                isLoading: false,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.large,
                onPressed: () async {
                  // Refresh user data to update isfpquestionanswered flag
                  await _userController.fetchUserProfile(
                    onLoading: (loading) {},
                  );

                  // Pop with success result to return to Complete Compliance screen
                  Navigator.pop(context, true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build answered state body (summary view)
  Widget _buildAnsweredStateBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              AppText(
                'Your Financial Profile',
                variant: AppTextVariant.headline4,
                weight: AppTextWeight.bold,
              ),
              const SizedBox(height: 8),
              AppText(
                'Review and edit your answers below',
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                lineHeight: 1.5,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),

        // Summary list
        Expanded(child: _buildSummaryView()),
      ],
    );
  }

  // Build question state body (question view)
  Widget _buildQuestionStateBody() {
    // Show loader while questions are loading
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar and question info
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizing.scaffoldHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress bar (hidden in edit mode)
              if (!_isEditingQuestion) ...[
                Semantics(
                  label: 'Assessment Progress',
                  child: LinearProgressIndicator(
                    value:
                        _totalQuestions > 0
                            ? (_currentQuestionIndex + 1) / _totalQuestions
                            : 0,
                    backgroundColor: Colors.grey[800],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Question counter (hidden in edit mode)
              if (!_isEditingQuestion)
                Semantics(
                  label: "Question ${_currentQuestionIndex + 1} of $_totalQuestions",
                  child: AppText(
                    "Question ${_currentQuestionIndex + 1} of $_totalQuestions",
                    variant: AppTextVariant.bodySmall,
                    colorType: AppTextColorType.secondary,
                  ),
                ),

              const SizedBox(height: 24),

              // Section title
              Semantics(
                header: true,
                child: AppText(
                  _currentSectionTitle,
                  variant: AppTextVariant.headline4,
                  weight: AppTextWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Section description
              AppText(
                _currentSectionDescription,
                variant: AppTextVariant.bodyMedium,
                colorType: AppTextColorType.secondary,
                lineHeight: 1.5,
              ),
              const SizedBox(height: 24),
              // Question
              Semantics(
                header: true,
                child: AppText(
                  _currentQuestionTitle,
                  variant: AppTextVariant.headline5,
                  weight: AppTextWeight.semiBold,
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),

        // Content based on API state
        (_questions == null || _questions!.isEmpty) && !_isEditingQuestion
            ? Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    AppText(
                      "Failed to load questions",
                      variant: AppTextVariant.headline6,
                      weight: AppTextWeight.semiBold,
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Retry',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.medium,
                      onPressed:
                          widget.isUserAnswered
                              ? _fetchQuestionsWithAnswers
                              : _fetchQuestions,
                    ),
                  ],
                ),
              ),
            )
            : Expanded(
              child:
                  _currentQuestion == null
                      ? const SizedBox.shrink()
                      : _currentQuestion!.type == Type.RANGE
                      ? _buildRangeSelector()
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizing.scaffoldHorizontalPadding,
                        ),
                        itemCount: _currentOptions.length,
                        itemBuilder: (context, index) {
                          final option = _currentOptions[index];
                          bool isSelected;
                          Widget trailingWidget;

                          // Get the question ID
                          final questionId = _currentQuestion!.id;

                          // Handle different selection types
                          if (_currentQuestion!.type == Type.MULTI) {
                            // Multi-select questions
                            final selectedOptions =
                                (_selectedAnswers[questionId]
                                    as List<String>?) ??
                                [];
                            isSelected = selectedOptions.contains(
                              option.optionvalue,
                            );
                            trailingWidget = Checkbox(
                              value: isSelected,
                              activeColor: Colors.green,
                              checkColor: Colors.white,
                              onChanged: (bool? value) {
                                _handleOptionSelection(option);
                              },
                            );
                          } else {
                            // Single select questions
                            isSelected =
                                _selectedAnswers[questionId] ==
                                option.optionvalue;
                            trailingWidget =
                                isSelected
                                    ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                    : const Icon(
                                      Icons.circle_outlined,
                                      color: Colors.white54,
                                    );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Semantics(
                              selected:
                                  _currentQuestion!.type != Type.MULTI
                                      ? isSelected
                                      : null,
                              checked:
                                  _currentQuestion!.type == Type.MULTI
                                      ? isSelected
                                      : null,
                              button: true,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.darkInputBackground,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? AppColors
                                                .darkButtonPrimaryBackground
                                            : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  title: AppText(
                                    option.optiontext,
                                    variant: AppTextVariant.bodyMedium,
                                    weight: AppTextWeight.medium,
                                  ),
                                  trailing: ExcludeSemantics(child: trailingWidget),
                                  onTap: () {
                                    _handleOptionSelection(option);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show success screen if submission is successful
    if (_isSubmissionSuccessful) {
      return _buildSuccessScreen();
    }

    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Semantics(
              button: true,
              label: 'Back',
              onTap: () async {
                if (_isEditingQuestion) {
                  _cancelEditing();
                } else {
                  final shouldPop = await _confirmExit();
                  if (shouldPop) {
                    Get.back();
                  }
                }
              },
              child: GestureDetector(
                onTap: () async {
                  if (_isEditingQuestion) {
                    _cancelEditing();
                  } else {
                    final shouldPop = await _confirmExit();
                    if (shouldPop) {
                      Get.back();
                    }
                  }
                },
                child: const Icon(
                  Icons.chevron_left,
                  size: 32,
                ),
              ),
            ),
            Semantics(
              header: true,
              child: AppText(
                "Financial Profiling",
                variant: AppTextVariant.headline6,
                weight: AppTextWeight.semiBold,
              ),
            ),
            const WhatsAppSupportButton(size: 20),
          ],
        ),
      ),
      body: SafeArea(
        child:
            widget.isUserAnswered && !_isEditingQuestion
                ? _buildAnsweredStateBody()
                : _buildQuestionStateBody(),
      ),
      bottomNavigationBar:
          _isLoading
              ? null
              : (!widget.isUserAnswered || _isEditingQuestion)
              ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizing.scaffoldHorizontalPadding,
                ),
                margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Error message placeholder (can be used for validation errors)
                    const SizedBox(height: 10),
                    if (_isEditingQuestion) ...[
                      // Cancel and Save buttons for editing
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Cancel',
                              variant: AppButtonVariant.secondary,
                              size: AppButtonSize.large,
                              onPressed: _cancelEditing,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppButton(
                              text: 'Save',
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.large,
                              onPressed:
                                  _isAnyOptionSelected
                                      ? _saveEditedQuestion
                                      : () {},
                              isDisabled: !_isAnyOptionSelected || _isLoading,
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Next/Submit button for normal flow
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text:
                                  _currentQuestionIndex < _totalQuestions - 1
                                      ? 'Next'
                                      : 'Submit',
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.large,
                              isDisabled: !_isAnyOptionSelected || _isLoading,
                              onPressed:
                                  _isAnyOptionSelected
                                      ? () {
                                        // Move to next question or submit
                                        if (_currentQuestionIndex <
                                            _totalQuestions - 1) {
                                          setState(() {
                                            _currentQuestionIndex++;
                                          });
                                        } else {
                                          // Submit answers
                                          _submitAnswers();
                                        }
                                      }
                                      : () {},
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              )
              : null,
      ),
    );
  }
}
