import '../../../config/router/route_names.dart';
import '../../../core/constants/ai_assistant_constants.dart';
import '../../../core/constants/review_yes_no_questions.dart';
import '../../reviews/models/review_model.dart';
import '../../../core/utils/indian_currency_formatter.dart';
import '../../colleges/models/college_model.dart';
import '../../student_life/models/student_life_models.dart';
import '../models/ai_college_data_bundle.dart';
import '../models/ai_source_citation.dart';
import '../models/ai_topic.dart';

class AiGroundedAnswer {
  final String text;
  final List<AiSourceCitation> sources;

  const AiGroundedAnswer({required this.text, this.sources = const []});
}

/// Builds answers strictly from College Reality data — no LLM, no guessing.
class AiGroundedAnswerBuilder {
  AiGroundedAnswer build({
    required AiCollegeDataBundle bundle,
    required AiTopic topic,
    required String query,
  }) {
    final college = bundle.college;
    final sources = <AiSourceCitation>[];
    final lines = <String>[];

    sources.add(_profileSource(college));

    switch (topic) {
      case AiTopic.cse:
        lines.addAll(_answerCse(bundle, sources));
      case AiTopic.placements:
        lines.addAll(_answerPlacements(bundle, sources));
      case AiTopic.hostel:
        lines.addAll(_answerHostel(bundle, sources));
      case AiTopic.package:
        lines.addAll(_answerPackage(bundle, sources));
      case AiTopic.ragging:
        lines.addAll(_answerRagging(bundle, sources));
      case AiTopic.faculty:
        lines.addAll(_answerFaculty(bundle, sources));
      case AiTopic.fees:
        lines.addAll(_answerFees(bundle, sources));
      case AiTopic.campusLife:
        lines.addAll(_answerCampusLife(bundle, sources));
      case AiTopic.examScore:
      case AiTopic.general:
        lines.addAll(_answerGeneral(bundle, sources, query));
    }

    if (lines.isEmpty) {
      lines.add(
        'I could not find enough verified data about ${college.name} for this question. '
        'Try asking about placements, hostel, fees, or CSE — or browse the college profile.',
      );
    }

    lines.add(
      '\nAll facts above are from College Reality profiles, verified reviews, '
      'student answers, or community posts — nothing is estimated or generated.',
    );

    return AiGroundedAnswer(
      text: lines.join('\n'),
      sources: _dedupeSources(sources),
    );
  }

  List<String> _answerCse(AiCollegeDataBundle bundle, List<AiSourceCitation> sources) {
    final college = bundle.college;
    final lines = <String>['**CSE / Computer Engineering at ${college.name}**'];

    final offersCse = college.displayCourses.any(
      (c) =>
          c.toLowerCase().contains('computer') ||
          c.toLowerCase().contains('cse') ||
          c.toLowerCase().contains('information technology'),
    );
    if (offersCse) {
      lines.add('Offers computer-related programs: ${college.displayCourses.where((c) {
        final l = c.toLowerCase();
        return l.contains('computer') || l.contains('cse') || l.contains('information');
      }).take(4).join(', ')}.');
    } else if (college.displayCourses.isNotEmpty) {
      lines.add(
        'Listed programs: ${college.displayCourses.take(5).join(', ')}. '
        'No explicit CSE/IT program found in our profile data.',
      );
    } else {
      lines.add('Course list not available in our profile data.');
    }

    if (college.aggregatedRatings.teaching > 0) {
      lines.add(
        'Teaching quality rating: ${college.aggregatedRatings.teaching.toStringAsFixed(1)}/5 '
        'from ${college.reviewCount} verified review${college.reviewCount == 1 ? '' : 's'}.',
      );
    }

    _addMatchingReviews(bundle, sources, lines, ['cse', 'computer', 'coding', 'it ']);
    _addMatchingAnswers(bundle, sources, lines, ['cse', 'computer', 'coding']);
    _addMatchingPosts(bundle, sources, lines, ['cse', 'computer', 'coding']);

    return lines;
  }

  List<String> _answerPlacements(
    AiCollegeDataBundle bundle,
    List<AiSourceCitation> sources,
  ) {
    final college = bundle.college;
    final p = college.placements;
    final lines = <String>['**Placements at ${college.name}**'];

    if (p.placementPercentage > 0) {
      lines.add('Placement rate: ${p.placementPercentage}%.');
    }
    if (p.averagePackageLpa > 0) {
      lines.add('Average package: ${p.averagePackageLpa.toStringAsFixed(1)} LPA.');
    }
    if (p.highestPackageLpa > 0) {
      lines.add('Highest package: ${p.highestPackageLpa.toStringAsFixed(1)} LPA.');
    }
    if (college.aggregatedRatings.placements > 0) {
      lines.add(
        'Students rated placements ${college.aggregatedRatings.placements.toStringAsFixed(1)}/5.',
      );
    }
    if (p.placementPercentage <= 0 && college.aggregatedRatings.placements <= 0) {
      lines.add('No placement statistics in our verified profile yet.');
    }

    _addMatchingReviews(bundle, sources, lines, ['placement', 'placed', 'company', 'recruit']);
    _addMatchingAnswers(bundle, sources, lines, ['placement', 'placed', 'company']);
    return lines;
  }

  List<String> _answerHostel(AiCollegeDataBundle bundle, List<AiSourceCitation> sources) {
    final college = bundle.college;
    final h = college.hostel;
    final lines = <String>['**Hostel at ${college.name}**'];

    if (h.available) {
      lines.add('Hostel available on campus.');
      if (h.annualFee > 0) {
        lines.add('Hostel fee: ${IndianCurrencyFormatter.format(h.annualFee)}.');
      }
      if (college.aggregatedRatings.hostel > 0) {
        lines.add(
          'Hostel rated ${college.aggregatedRatings.hostel.toStringAsFixed(1)}/5 '
          'by verified students.',
        );
      }
    } else {
      lines.add('Profile data indicates hostel may not be available on campus.');
    }

    _addMatchingReviews(bundle, sources, lines, ['hostel', 'mess', 'room', 'accommodation']);
    _addMatchingAnswers(bundle, sources, lines, ['hostel', 'mess']);
    _addMatchingPosts(bundle, sources, lines, ['hostel', 'mess']);
    return lines;
  }

  List<String> _answerPackage(AiCollegeDataBundle bundle, List<AiSourceCitation> sources) {
    final college = bundle.college;
    final lines = <String>['**Packages at ${college.name}**'];
    final p = college.placements;

    if (p.averagePackageLpa > 0) {
      lines.add('Average package: ${p.averagePackageLpa.toStringAsFixed(1)} LPA.');
    }
    if (p.highestPackageLpa > 0) {
      lines.add('Highest package: ${p.highestPackageLpa.toStringAsFixed(1)} LPA.');
    }
    if (p.placementPercentage > 0) {
      lines.add('Placement rate: ${p.placementPercentage}%.');
    }
    if (p.averagePackageLpa <= 0 && p.highestPackageLpa <= 0) {
      lines.add('Package data not available in verified profile.');
    }

    _addMatchingReviews(bundle, sources, lines, ['lpa', 'package', 'salary', 'ctc']);
    _addMatchingAnswers(bundle, sources, lines, ['lpa', 'package', 'salary']);
    return lines;
  }

  List<String> _answerRagging(AiCollegeDataBundle bundle, List<AiSourceCitation> sources) {
    final college = bundle.college;
    final lines = <String>['**Ragging at ${college.name}**'];

    var yesCount = 0;
    var noCount = 0;
    var answered = 0;
    for (final review in bundle.reviews) {
      final val = review.yesNoAnswers[ReviewYesNoQuestions.raggingPresent];
      if (val == null) continue;
      answered++;
      if (val) {
        yesCount++;
      } else {
        noCount++;
      }
    }

    if (answered > 0) {
      lines.add(
        'From $answered verified review${answered == 1 ? '' : 's'} with ragging survey: '
        '$yesCount reported ragging, $noCount said no ragging.',
      );
    } else {
      lines.add('No ragging survey responses in verified reviews yet.');
    }

    _addMatchingReviews(bundle, sources, lines, ['ragging', 'bullying', 'senior']);
    _addMatchingAnswers(bundle, sources, lines, ['ragging']);
    _addMatchingPosts(bundle, sources, lines, ['ragging']);
    return lines;
  }

  List<String> _answerFaculty(AiCollegeDataBundle bundle, List<AiSourceCitation> sources) {
    final college = bundle.college;
    final lines = <String>['**Faculty at ${college.name}**'];

    if (college.aggregatedRatings.faculty > 0) {
      lines.add(
        'Faculty rated ${college.aggregatedRatings.faculty.toStringAsFixed(1)}/5.',
      );
    }
    if (college.aggregatedRatings.teaching > 0) {
      lines.add(
        'Teaching quality: ${college.aggregatedRatings.teaching.toStringAsFixed(1)}/5.',
      );
    }

    _addMatchingReviews(bundle, sources, lines, ['faculty', 'professor', 'teaching']);
    _addMatchingAnswers(bundle, sources, lines, ['faculty', 'professor']);
    return lines;
  }

  List<String> _answerFees(AiCollegeDataBundle bundle, List<AiSourceCitation> sources) {
    final college = bundle.college;
    final lines = <String>['**Fees at ${college.name}**'];
    final fees = college.fees;

    if (fees.tuitionMin > 0 || fees.tuitionMax > 0) {
      lines.add(
        'Annual tuition: ${IndianCurrencyFormatter.formatRange(min: fees.tuitionMin, max: fees.tuitionMax)}.',
      );
    }
    if (college.aggregatedRatings.fees > 0) {
      lines.add(
        'Value-for-money rating: ${college.aggregatedRatings.fees.toStringAsFixed(1)}/5.',
      );
    }

    _addMatchingReviews(bundle, sources, lines, ['fees', 'fee', 'tuition', 'cost']);
    return lines;
  }

  List<String> _answerCampusLife(
    AiCollegeDataBundle bundle,
    List<AiSourceCitation> sources,
  ) {
    final college = bundle.college;
    final lines = <String>['**Campus life at ${college.name}**'];

    if (college.aggregatedRatings.campusLife > 0) {
      lines.add(
        'Campus life rated ${college.aggregatedRatings.campusLife.toStringAsFixed(1)}/5.',
      );
    }
    if (college.wouldChooseAgainPercent != null) {
      lines.add(
        '${college.wouldChooseAgainPercent!.round()}% of reviewers would choose this college again.',
      );
    }

    _addMatchingReviews(bundle, sources, lines, ['campus', 'fest', 'culture', 'life']);
    _addMatchingPosts(bundle, sources, lines, ['fest', 'event', 'campus']);
    return lines;
  }

  List<String> _answerGeneral(
    AiCollegeDataBundle bundle,
    List<AiSourceCitation> sources,
    String query,
  ) {
    final college = bundle.college;
    final lines = <String>['**About ${college.name}**'];
    final q = query.toLowerCase();

    if (college.reviewCount > 0 && college.aggregatedRatings.overall > 0) {
      lines.add(
        'Overall rating: ${college.aggregatedRatings.overall.toStringAsFixed(1)}/5 '
        'from ${college.reviewCount} verified review${college.reviewCount == 1 ? '' : 's'}.',
      );
    }
    lines.add('Location: ${college.locationLabel}. Type: ${_capitalize(college.type)}.');

    if (college.accreditation.naacGrade?.isNotEmpty == true) {
      lines.add('NAAC: ${college.accreditation.naacGrade}.');
    }

    final keywords = q.split(RegExp(r'\s+')).where((w) => w.length > 3).take(6).toList();
    _addMatchingReviews(bundle, sources, lines, keywords);
    _addMatchingAnswers(bundle, sources, lines, keywords);
    _addMatchingPosts(bundle, sources, lines, keywords);

    if (bundle.reviews.isNotEmpty && lines.length <= 3) {
      final top = bundle.reviews.first;
      if (top.textReview.isNotEmpty) {
        lines.add('Recent verified review excerpt: "${_excerpt(top.textReview)}"');
        sources.add(_reviewSource(top, college.id));
      }
    }

    return lines;
  }

  void _addMatchingReviews(
    AiCollegeDataBundle bundle,
    List<AiSourceCitation> sources,
    List<String> lines,
    List<String> keywords,
  ) {
    var added = 0;
    for (final review in bundle.reviews) {
      if (added >= 2) break;
      final text = '${review.textReview} ${review.pros.join(' ')} ${review.cons.join(' ')}'
          .toLowerCase();
      if (keywords.any((k) => k.isNotEmpty && text.contains(k)) &&
          review.textReview.isNotEmpty) {
        lines.add('Verified review: "${_excerpt(review.textReview)}"');
        sources.add(_reviewSource(review, bundle.college.id));
        added++;
      }
    }
  }

  void _addMatchingAnswers(
    AiCollegeDataBundle bundle,
    List<AiSourceCitation> sources,
    List<String> lines,
    List<String> keywords,
  ) {
    var added = 0;
    for (final snippet in bundle.verifiedAnswers) {
      if (added >= 2) break;
      final body = snippet.answer.body.toLowerCase();
      final title = snippet.question.title.toLowerCase();
      final match = keywords.isEmpty ||
          keywords.any((k) => k.isNotEmpty && (body.contains(k) || title.contains(k)));
      if (match && snippet.answer.body.isNotEmpty) {
        lines.add(
          'Verified student answer on "${snippet.question.title}": '
          '"${_excerpt(snippet.answer.body)}"',
        );
        sources.add(_answerSource(snippet, bundle.college.id));
        added++;
      }
    }
  }

  void _addMatchingPosts(
    AiCollegeDataBundle bundle,
    List<AiSourceCitation> sources,
    List<String> lines,
    List<String> keywords,
  ) {
    var added = 0;
    for (final post in bundle.communityPosts) {
      if (added >= 1) break;
      final content = post.content.toLowerCase();
      if (keywords.isEmpty ||
          keywords.any((k) => k.isNotEmpty && content.contains(k))) {
        if (post.content.isNotEmpty) {
          lines.add('Community post: "${_excerpt(post.content)}"');
          sources.add(_postSource(post, bundle.college.id, bundle.college.name));
          added++;
        }
      }
    }
  }

  AiSourceCitation _profileSource(CollegeModel college) {
    return AiSourceCitation(
      type: AiSourceType.profile,
      id: college.id,
      label: 'College profile',
      excerpt: college.name,
      actionRoute: RouteNames.collegeDetailsPath(college.id),
    );
  }

  AiSourceCitation _reviewSource(ReviewModel review, String collegeId) {
    return AiSourceCitation(
      type: AiSourceType.review,
      id: review.id,
      label: 'Verified review',
      excerpt: _excerpt(review.textReview),
      actionRoute: RouteNames.collegeDetailsPath(collegeId, tab: 'reviews'),
    );
  }

  AiSourceCitation _answerSource(AiAnswerSnippet snippet, String collegeId) {
    return AiSourceCitation(
      type: AiSourceType.answer,
      id: snippet.answer.id,
      label: 'Verified answer',
      excerpt: _excerpt(snippet.answer.body),
      actionRoute: RouteNames.collegeQuestionPath(collegeId, snippet.question.id),
    );
  }

  AiSourceCitation _postSource(
    StudentCommunityPostModel post,
    String collegeId,
    String collegeName,
  ) {
    return AiSourceCitation(
      type: AiSourceType.communityPost,
      id: post.id,
      label: 'Community post',
      excerpt: _excerpt(post.content),
      actionRoute: RouteNames.collegeCommunityFeedPath(collegeId, name: collegeName),
    );
  }

  String _excerpt(String text) {
    final trimmed = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.length <= AiAssistantConstants.maxSourceExcerptLength) {
      return trimmed;
    }
    return '${trimmed.substring(0, AiAssistantConstants.maxSourceExcerptLength)}…';
  }

  List<AiSourceCitation> _dedupeSources(List<AiSourceCitation> sources) {
    final seen = <String>{};
    return sources.where((s) {
      final key = '${s.type.name}_${s.id}';
      if (seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).take(6).toList();
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}
