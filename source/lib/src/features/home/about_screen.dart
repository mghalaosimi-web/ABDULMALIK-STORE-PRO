import 'package:flutter/material.dart';

/// Presents the project's academic, advisory, engineering, and development team.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final theme = Theme.of(context);

    final academicBoard = <_Profile>[
      _Profile(
        name: ar ? 'الأستاذ الدكتور أحمد الناشري' : 'Prof. Dr. Ahmed Al-Nashiri',
        title: ar ? 'متخصص تخطيط هياكل البيانات ومعمارية قواعد البيانات' : 'Academic Data Architecture & Database Planning Specialist',
        duties: ar
            ? ['وضع التصور الأولي لهياكل البيانات.', 'تخطيط وتصميم البنية المنطقية لقواعد البيانات.', 'تحديد العلاقات بين الكيانات والبيانات.', 'المساهمة في وضع الأسس العلمية لتنظيم البيانات وإدارتها.']
            : ['Define the initial data-structure blueprint.', 'Plan and design the logical database architecture.', 'Define relationships between entities and data.', 'Contribute scientific foundations for data organization and management.'],
        credentials: ar
            ? ['الدكتوراه – جامعة الملك سعود، المملكة العربية السعودية.', 'درجة الأستاذية (Professor).']
            : ['PhD – King Saud University, Saudi Arabia.', 'Professor.'],
      ),
      _Profile(
        name: ar ? 'الأستاذ الدكتور عبد الرزاق الأهدل' : 'Prof. Dr. Abdulrazzaq Al-Ahdal',
        title: ar ? 'المشرف الأكاديمي والعلمي ومهندس معمارية النظام' : 'Academic Supervisor & System Architect',
        duties: ar
            ? ['الإشراف على الهيكلة العامة للنظام.', 'تصميم المعمارية الخلفية والأمامية.', 'إعداد الخطة الهندسية والتقنية المتكاملة.', 'تقديم الإشراف العلمي والمساهمات المعرفية.', 'مراجعة التصورات المعمارية والتقنية للمشروع.']
            : ['Supervise the overall system structure.', 'Design backend and frontend architecture.', 'Prepare the integrated engineering and technical plan.', 'Provide scientific guidance and knowledge contributions.', 'Review the project’s architectural and technical designs.'],
        credentials: ar
            ? ['الدكتوراه – جامعة سوامي راماناند تيرث ماراثوادا (SRTMUN)، ناندِد، الهند.', 'درجة الأستاذية (Professor).']
            : ['PhD – Swami Ramanand Teerth Marathwada University (SRTMUN), Nanded, India.', 'Professor.'],
      ),
      _Profile(
        name: ar ? 'الدكتور ضياء الحق القدمي' : 'Dr. Diaa Al-Haq Al-Qudmi',
        title: ar ? 'مستشار التشفير وأمن الشبكات والأدلة الجنائية الرقمية' : 'Cryptography, Network Security & Digital Forensics Advisor',
        duties: ar
            ? ['الإشراف الاستشاري على تقنيات التشفير والتحقق الرقمي.', 'تقديم المشورة في أمن الاتصالات والشبكات.', 'مراجعة الجوانب التقنية للأدلة الجنائية الرقمية.', 'المساهمة في تعزيز حماية البيانات وسلامة المعلومات.']
            : ['Advise on cryptography and digital verification.', 'Provide guidance on communications and network security.', 'Review technical aspects of digital forensics.', 'Help strengthen data protection and information integrity.'],
        credentials: ar
            ? ['الدكتوراه في هندسة الاتصالات والشبكات – جامعة قالمة، الجزائر.', 'سنة التخرج: 2024.']
            : ['PhD in Communications and Network Engineering – University of Guelma, Algeria.', 'Graduation year: 2024.'],
      ),
      _Profile(
        name: ar ? 'الدكتور عبده شويه' : 'Dr. Abduh Shuwayh',
        title: ar ? 'مستشار تحليل المشاريع وإدارة المشروع' : 'Project Analysis & Management Consultant',
        duties: ar
            ? ['المساهمة في تحليل فكرة المشروع وتقييم أهدافه.', 'تقديم الرؤى والمقترحات التطويرية.', 'المساهمة في التخطيط الإداري والتنظيمي.', 'المشاركة في متابعة مراحل تنفيذ المشروع.']
            : ['Analyze the project concept and assess its objectives.', 'Provide insights and development recommendations.', 'Contribute to administrative and organizational planning.', 'Support follow-up across project implementation stages.'],
        credentials: ar
            ? ['الدكتوراه – جامعة عبد المالك السعدي، المملكة المغربية.']
            : ['PhD – Abdelmalek Essaâdi University, Morocco.'],
      ),
      _Profile(
        name: ar ? 'الأستاذة سمر' : 'Ms. Samar',
        title: ar ? 'أخصائية تصميم تجربة المستخدم وواجهات الاستخدام' : 'UI/UX Design Specialist',
        duties: ar
            ? ['تحليل تجربة المستخدم (UX) وتصميم واجهات الاستخدام (UI).', 'تحسين سهولة الاستخدام والتنقل داخل النظام.', 'تطوير التصورات البصرية للشاشات.', 'تعزيز اتساق الهوية البصرية والتفاعل مع النظام.']
            : ['Analyze user experience (UX) and design user interfaces (UI).', 'Improve usability and navigation.', 'Develop visual concepts for screens.', 'Strengthen visual consistency and user interaction.'],
        credentials: ar
            ? ['درجة الماجستير – جامعة صنعاء.']
            : ['Master’s degree – Sana’a University.'],
      ),
    ];

    final developmentTeam = <_Profile>[
      _Profile(
        name: ar ? 'محمد غالب العصيمي' : 'Mohammed Ghaleb Al-Osaimi',
        subtitle: 'Mohammed Ghaleb Alaosimi',
        title: ar ? 'المطور الرئيسي ومهندس النظام' : 'Lead Full-Stack Developer & System Engineer',
        duties: ar
            ? ['هندسة النظام والإشراف على تنفيذ مكوناته البرمجية.', 'تطوير الواجهات الأمامية والخلفية.', 'تصميم المكونات البرمجية وإدارة قواعد البيانات والبيانات التشغيلية.', 'تشغيل النظام ومتابعة أدائه وإعداد التقارير الفنية والتشغيلية.', 'إجراء الاختبارات ومتابعة جودة التنفيذ والتكامل بين الخدمات.', 'إعداد الخطط التنفيذية والتصورات التقنية ومتابعة دورة حياة التطوير.']
            : ['Engineer the system and oversee implementation of its software components.', 'Develop frontend and backend applications.', 'Design software components and manage databases and operational data.', 'Operate the system, monitor performance, and prepare technical and operational reports.', 'Test the system and oversee implementation quality and service integration.', 'Prepare technical plans and oversee the development lifecycle.'],
        credentials: ar
            ? ['طالب بكالوريوس تقنية المعلومات – كلية المنار الجامعية.', 'اهتمامات: تطوير البرمجيات الشامل، هندسة البرمجيات، معمارية الأنظمة، إدارة قواعد البيانات، والأمن السيبراني.', 'شهادات ودورات: Cisco، إدراك، وLinux Foundation.']
            : ['BSc student in Information Technology – Al-Manar University College.', 'Focus areas: full-stack development, software engineering, system architecture, database management, and cybersecurity.', 'Certificates and learning: Cisco, Edraak, and Linux Foundation.'],
      ),
      _Profile(
        name: ar ? 'رمزي محمد الصرابي' : 'Ramzi Mohammed Al-Sarabi',
        title: ar ? 'مؤسس فكرة المشروع ومالك النظام والمطور المشارك' : 'Project Founder, System Owner & Software Developer',
        duties: ar
            ? ['صاحب الفكرة والمبادرة الأساسية للمشروع.', 'المساهمة في تنفيذ النظام وتطوير مكوناته.', 'المشاركة في تحديد رؤية المنتج وتوجهه العام.', 'اقتراح الحلول التقنية والمساهمة في تصميم المعمارية الداخلية.', 'متابعة الجوانب المتعلقة بملكية النظام وتسويقه وبيعه.']
            : ['Originated the project idea and initial initiative.', 'Contribute to implementation and development of system components.', 'Help define the product vision and direction.', 'Propose technical solutions and contribute to internal architecture.', 'Oversee matters related to system ownership, marketing, and sales.'],
        credentials: ar
            ? ['بكالوريوس تقنية المعلومات – كلية المنار الجامعية.', 'خبرة عملية لمدة ثلاث سنوات في التطوير البرمجي وتطوير الحلول التقنية وتنفيذ الأنظمة.']
            : ['Bachelor’s degree in Information Technology – Al-Manar University College.', 'Three years of practical experience in software development, technical solutions, and system implementation.'],
      ),
      _Profile(
        name: ar ? 'عرفات الكاملي' : 'Arafat Al-Kamali',
        title: ar ? 'مهندس أمن سيبراني واختبار اختراق أخلاقي' : 'Cybersecurity Engineer & Ethical Penetration Tester',
        duties: ar
            ? ['إعداد التصورات والخطط الأمنية لحماية البنية التقنية.', 'تنفيذ اختبارات الاختراق الأخلاقي ضمن نطاق مصرح به.', 'اختبار الثغرات وتحليل المخاطر وتقييم مستوى الحماية.', 'إعداد التقارير الأمنية وتوثيق النتائج.', 'اقتراح المعالجات والمساهمة في تحسين الوضع الأمني للنظام.']
            : ['Develop security plans to protect the technical infrastructure.', 'Conduct authorized ethical penetration tests.', 'Test vulnerabilities, analyze risks, and assess security posture.', 'Prepare security reports and document findings.', 'Recommend remediation and improve the system’s security posture.'],
        credentials: ar
            ? ['بكالوريوس الأمن السيبراني – كلية المنار الجامعية.', 'مجالات وشهادات: Cisco، أمن الشبكات، اختبار الاختراق الأخلاقي، وتحليل الثغرات الأمنية.']
            : ['Bachelor’s degree in Cybersecurity – Al-Manar University College.', 'Areas and certificates: Cisco, network security, ethical penetration testing, and vulnerability analysis.'],
      ),
    ];

    final structure = ar
        ? ['الإشراف الأكاديمي والعلمي', 'هندسة قواعد البيانات وهياكل المعلومات', 'معمارية النظام والتخطيط التقني', 'تطوير الواجهات الأمامية والخلفية', 'تصميم تجربة المستخدم وواجهات الاستخدام', 'الأمن السيبراني وحماية المعلومات', 'التشفير والأدلة الجنائية الرقمية', 'إدارة المشروع وتحليل المتطلبات', 'ضمان الجودة والاختبارات']
        : ['Academic and scientific supervision', 'Database architecture and information structures', 'System architecture and technical planning', 'Frontend and backend development', 'UI/UX design', 'Cybersecurity and information protection', 'Cryptography and digital forensics', 'Project management and requirements analysis', 'Quality assurance and testing'];

    final methodology = ar
        ? ['البحث والتحليل ودراسة المتطلبات', 'تخطيط وتصميم المعمارية التقنية', 'هندسة قواعد البيانات وهياكل المعلومات', 'تصميم واجهات وتجربة المستخدم', 'التطوير البرمجي المتكامل', 'هندسة الأمن والحماية والتشفير', 'الاختبارات وضمان الجودة', 'النشر والتشغيل وإدارة النظام', 'الصيانة والتحسين والتطوير المستمر']
        : ['Research, analysis, and requirements discovery', 'Technical architecture planning and design', 'Database and information-structure engineering', 'UI/UX design', 'Full-stack development', 'Security engineering and cryptography', 'Quality assurance and testing', 'Deployment, operations, and system management', 'Maintenance and continuous improvement'];

    return Scaffold(
      appBar: AppBar(title: Text(ar ? 'عن المشروع والفريق' : 'Project Team & Structure')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _CompanyProfileCard(),
            const SizedBox(height: 14),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [theme.colorScheme.primaryContainer, theme.colorScheme.surface],
                  ),
                ),
                child: Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/icon/app_icon.png', width: 68, height: 68),
                  ),
                  const SizedBox(height: 12),
                  Text('PROJECT TEAM & ORGANIZATIONAL STRUCTURE',
                      textAlign: TextAlign.center, textDirection: TextDirection.ltr,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('فريق العمل والهيكل الأكاديمي والتقني للمشروع',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(ar
                      ? 'يضم المشروع أكاديميين ومستشارين ومتخصصين ومهندسين ومطورين، تتكامل أدوارهم في التخطيط الأكاديمي والهندسة البرمجية وقواعد البيانات والأمن السيبراني وتجربة المستخدم وإدارة المشاريع.'
                      : 'The project brings together academics, advisors, specialists, engineers, and developers across academic planning, software and database engineering, cybersecurity, user experience, and project management.',
                      textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(ar
                      ? 'يعمل الفريق وفق رؤية تكاملية لبناء نظام يعتمد أسساً علمية وهندسية ومعايير تطوير احترافية، مع التركيز على الجودة والأمان وقابلية التوسع والاستدامة.'
                      : 'The team follows an integrated vision for a system grounded in scientific and engineering principles, professional development standards, quality, security, scalability, and sustainability.',
                      textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                ]),
              ),
            ),
            const SizedBox(height: 18),
            _SectionHeading(title: ar ? 'أولاً: اللجنة الأكاديمية والاستشارية' : 'FIRST: ACADEMIC & ADVISORY BOARD', icon: Icons.school_outlined),
            for (final profile in academicBoard) _ProfileCard(profile: profile),
            const SizedBox(height: 12),
            _SectionHeading(title: ar ? 'ثانياً: فريق الهندسة والتطوير' : 'SECOND: ENGINEERING & DEVELOPMENT TEAM', icon: Icons.code_rounded),
            for (final profile in developmentTeam) _ProfileCard(profile: profile),
            const SizedBox(height: 12),
            _SectionHeading(title: ar ? 'ثالثاً: الهيكل التنظيمي للمشروع' : 'THIRD: PROJECT ORGANIZATIONAL STRUCTURE', icon: Icons.account_tree_outlined),
            _NumberedPanel(items: structure),
            const SizedBox(height: 12),
            _SectionHeading(title: ar ? 'رابعاً: منهجية تطوير المشروع' : 'FOURTH: PROJECT DEVELOPMENT METHODOLOGY', icon: Icons.alt_route_rounded),
            _NumberedPanel(items: methodology),
            const SizedBox(height: 12),
            _SectionHeading(title: ar ? 'رؤية المشروع' : 'PROJECT VISION', icon: Icons.visibility_outlined),
            Card(child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(ar
                  ? 'يهدف المشروع إلى تقديم منظومة تقنية متكاملة تجمع بين الخبرة الأكاديمية والمعرفة العلمية والتنفيذ الهندسي والابتكار البرمجي. ويستند العمل إلى تكامل الأدوار بين اللجنة الأكاديمية والاستشارية وفريق الهندسة والتطوير، لتحويل الأفكار والمتطلبات إلى حلول عملية آمنة وقابلة للتوسع ومستدامة. ويؤمن الفريق بأن جودة الأنظمة التقنية لا تعتمد على البرمجة وحدها، بل على التكامل بين التخطيط العلمي والمعمارية والتصميم والتنفيذ والأمن والاختبار والإدارة.'
                  : 'The project aims to deliver an integrated technology platform combining academic expertise, scientific knowledge, engineering execution, and software innovation. Its work depends on collaboration between the academic and advisory board and the engineering and development team to turn requirements into practical, secure, scalable, and sustainable solutions. The team believes that software quality depends not on coding alone, but on the integration of research, architecture, design, implementation, security, testing, and management.',
                  style: theme.textTheme.bodyMedium),
            )),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Profile {
  const _Profile({
    required this.name,
    required this.title,
    required this.duties,
    required this.credentials,
    this.subtitle,
  });

  final String name;
  final String title;
  final List<String> duties;
  final List<String> credentials;
  final String? subtitle;
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 14, 4, 10),
      child: Row(children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(child: Text(title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
      ]),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.profile});
  final _Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
        childrenPadding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 16),
        leading: CircleAvatar(
          radius: 23,
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Icon(Icons.person_outline_rounded,
              color: theme.colorScheme.onSecondaryContainer, size: 25),
        ),
        title: Text(profile.name,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (profile.subtitle != null)
              Text(profile.subtitle!, textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodySmall),
            Text(profile.title,
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
          ]),
        ),
        children: [
          const Divider(height: 12),
          _ListBlock(title: ar ? 'المسؤوليات والمهام' : 'Responsibilities', items: profile.duties),
          const SizedBox(height: 10),
          _ListBlock(title: ar ? 'المؤهلات والخبرات' : 'Qualifications & Experience', items: profile.credentials),
        ],
      ),
    );
  }
}

class _CompanyProfileCard extends StatelessWidget {
  const _CompanyProfileCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final cs = theme.colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: AlignmentDirectional.topStart,
            end: AlignmentDirectional.bottomEnd,
            colors: [cs.primaryContainer, cs.surface],
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text('M', style: theme.textTheme.headlineMedium?.copyWith(
                color: cs.onPrimary, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('M.GH.AL', textDirection: TextDirection.ltr,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1.4)),
              Text(ar ? 'شركة للبرمجيات والأنظمة والتطبيقات' : 'Software, Systems & Applications Company',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ])),
          ]),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.78),
              border: Border.all(color: cs.primary.withValues(alpha: 0.45)),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.verified_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 7),
              Flexible(child: Text(
                ar ? 'شارة توثيق تعريفية للمشروع ضمن أعمال M.GH.AL' : 'Project identity mark — an M.GH.AL portfolio project',
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold))),
            ]),
          ),
          const SizedBox(height: 14),
          Text(ar
              ? 'شركة M.GH.AL للبرمجيات والأنظمة والتطبيقات جهة تقنية متخصصة في تصميم وتطوير الحلول الرقمية، وبناء الأنظمة الإدارية والتشغيلية، وتطوير تطبيقات الأعمال، وأتمتة الإجراءات وسير العمل. ترتكز أعمالها على تحويل احتياجات المؤسسات والمنشآت إلى منتجات تقنية عملية تجمع بين هندسة البرمجيات، وتنظيم البيانات، وتجربة المستخدم، والتكامل بين الأنظمة.'
              : 'M.GH.AL Software, Systems & Applications is a software and technology company focused on designing and developing digital solutions, business and operational systems, business applications, and workflow automation. Its approach turns organizational needs into practical technology products through software engineering, structured data, user experience, and system integration.',
            style: theme.textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text(ar ? 'مجالات العمل' : 'Areas of Practice',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 7, runSpacing: 7, children: [
            for (final label in (ar
              ? ['البرمجيات المخصصة', 'أنظمة ERP والإدارة', 'تطبيقات الويب والهواتف', 'أتمتة الأعمال والإجراءات', 'قواعد البيانات والتكامل', 'لوحات المعلومات والتقارير', 'التحول الرقمي', 'الصيانة والدعم التقني']
              : ['Custom Software', 'ERP & Management Systems', 'Web & Mobile Apps', 'Business Process Automation', 'Databases & Integration', 'Dashboards & Reporting', 'Digital Transformation', 'Technical Support']))
              Chip(label: Text(label), visualDensity: VisualDensity.compact),
          ]),
          const SizedBox(height: 10),
          Text(ar
              ? 'الرؤية: بناء حلول موثوقة وقابلة للتوسع تساعد الأفراد والمنشآت على إدارة أعمالهم بكفاءة، وتقليل العمل اليدوي، وتحسين جودة القرار والتشغيل.'
              : 'Vision: Build reliable, scalable solutions that help people and organizations manage operations efficiently, reduce manual work, and improve decision-making.',
            style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(ar
              ? 'تنويه: هذه شارة هوية وتعريف بالمشروع ضمن ملف أعمال العلامة M.GH.AL، وليست شهادة اعتماد حكومية أو تصديقاً من جهة خارجية.'
              : 'Notice: This is a brand identity and portfolio mark for M.GH.AL, not a government accreditation or third-party certification.',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ]),
      ),
    );
  }
}

class _ListBlock extends StatelessWidget {
  const _ListBlock({required this.title, required this.items});
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      for (final item in items)
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 3),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('•  ', style: theme.textTheme.bodyMedium),
            Expanded(child: Text(item, style: theme.textTheme.bodyMedium)),
          ]),
        ),
    ]);
  }
}

class _NumberedPanel extends StatelessWidget {
  const _NumberedPanel({required this.items});
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${i + 1}'.padLeft(2, '0'),
                      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(items[i], style: theme.textTheme.bodyMedium),
                )),
              ]),
            ),
        ]),
      ),
    );
  }
}
