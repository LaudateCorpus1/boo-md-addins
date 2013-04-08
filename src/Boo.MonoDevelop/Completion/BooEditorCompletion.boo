namespace Boo.MonoDevelop.Completion

import System
import Boo.Lang.PatternMatching

import MonoDevelop.Ide.Gui
import MonoDevelop.Ide.CodeCompletion

import Boo.Ide
import Boo.MonoDevelop.Util.Completion

class BooEditorCompletion(BooCompletionTextEditorExtension):
	
	# Match "blah as [...]" pattern
	static AS_PATTERN = /\bas\s+(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?/
	
	# Match "Blah[of ...]" pattern
	static OF_PATTERN = /\bof\s+(?<namespace>[\w\d]+(\.[\w\d]+)*)?\.?/
	
	# Patterns that result in us doing a type completion
	static TYPE_PATTERNS = (OF_PATTERN, AS_PATTERN)
	
	# Patterns that result in us doing a namespace completion
	static NAMESPACE_PATTERNS = (IMPORTS_PATTERN,)
	
	# Delimiters that indicate a literal
	static LITERAL_DELIMITERS = ['"', '/']
	
	# Scraped from boo.g
	private static KEYWORDS = (
		"abstract",
		"and",
		"as",
		"break",
		"continue",
		"callable",
		"cast",
		"char",
		"class",
		"constructor",
		"def",
		"destructor",
		"do",
		"elif",
		"else",
		"ensure",
		"enum",
		"event",
		"except",
		"failure",
		"final",
		"from",
		"for",
		"false",
		"get",
		"goto",
		"import",
		"interface",
		"internal",
		"is",
		"isa",
		"if",
		"in",
		"namespace",
		"new",
		"not",
		"null",
		"of",
		"or",
		"override",
		"pass",
		"partial",
		"public",
		"protected",
		"private",
		"raise",
		"ref",
		"return",
		"set",
		"self",
		"super",
		"static",
		"struct",
		"then",
		"try",
		"transient",
		"true",
		"typeof",
		"unless",
		"virtual",
		"while",
		"yield",
		
		// BUILTINS
		"len",
		"print"
	)
        
  # Scraped from Types.cs
	private static PRIMITIVES = (
		"byte",
		"sbyte",
		"short",
		"ushort",
		"int",
		"uint",
		"long",
		"ulong",
		"single",
		"double",
		"decimal",
		"void",
		"string",
		"object"
	)
        
	override Keywords:
		get: return KEYWORDS
		
	override Primitives:
		get: return PRIMITIVES
		
#	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char):
#		triggerWordLength = 0
#		return HandleCodeCompletion(context, completionChar, triggerWordLength)
		
	override def HandleCodeCompletion(context as CodeCompletionContext, completionChar as char, ref triggerWordLength as int):
#		print "HandleCodeCompletion(${context.ToString()}, ${completionChar.ToString()})"
		triggerWordLength = 0
		line = GetLineText(context.TriggerLine)
		tokenLineOffset = context.TriggerLineOffset-1
		
		if(IsInsideComment(line, tokenLineOffset) or \
		   IsInsideLiteral(line, tokenLineOffset)):
			return null
		
		match completionChar.ToString():
			case " ":
				if (null != (completions = CompleteNamespacePatterns(context))):
					return completions
				return CompleteTypePatterns(context)
			case ".":
				if (null != (completions = CompleteNamespacePatterns(context))):
					return completions
				if (null != (completions = CompleteTypePatterns(context))):
					return completions
				return CompleteMembers(context)
			otherwise:
				if(CanStartIdentifier(completionChar)):
					if(StartsIdentifier(line, tokenLineOffset)):
						completions = CompleteVisible(context)
						# Necessary for completion window to take first identifier character into account
						--context.TriggerOffset 
						triggerWordLength = 1
					else:
						dotLineOffset = tokenLineOffset-1
						if(0 <= dotLineOffset and line.Length > dotLineOffset and "."[0] == line[dotLineOffset]):
							--context.TriggerOffset
							triggerWordLength = 1
							return CompleteMembers(context)
					
					return completions
		return null
				
	def CompleteNamespacePatterns(context as CodeCompletionContext):
#		types = (MemberType.Namespace, MemberType.Type)
#		for pattern in NAMESPACE_PATTERNS:
#			completions = CompleteNamespacesForPattern(context, pattern, "namespace", types)
#			return completions if completions is not null
			
		return null
		
	def CompleteTypePatterns(context as CodeCompletionContext):
#		types = (MemberType.Namespace, MemberType.Type)
#		
#		for pattern in TYPE_PATTERNS:
#			completions = CompleteNamespacesForPattern(context, pattern, "namespace", types)
#			if completions is not null:
#				completions.AddRange(CompletionData(p, Stock.Literal) for p in Primitives)
#				return completions
		return null
			
	override def ShouldEnableCompletionFor(fileName as string):
		return Boo.MonoDevelop.ProjectModel.BooLanguageBinding.IsBooFile(fileName)
		
	def IsInsideLiteral(line as string, offset as int):
		fragment = line[0:offset+1]
		for delimiter in LITERAL_DELIMITERS:
			list = List[of string]()
			list.Add(delimiter)
			if 0 == fragment.Split(list.ToArray(), StringSplitOptions.None).Length % 2:
				return true
		return false
	
	override SelfReference:
		get: return "self"
		
	override EndStatement:
		get: return string.Empty
		
	override def GetParameterDataProviderFor(methods as List of MethodDescriptor):
		return BooParameterDataProvider(Document, methods)
