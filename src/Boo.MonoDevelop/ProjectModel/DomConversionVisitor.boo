namespace Boo.MonoDevelop.ProjectModel


import Boo.Lang.Compiler.Ast
import Boo.Lang.PatternMatching

import MonoDevelop.Core
import MonoDevelop.Ide.TypeSystem

import ICSharpCode.NRefactory
import ICSharpCode.NRefactory.CSharp
import ICSharpCode.NRefactory.TypeSystem
import ICSharpCode.NRefactory.TypeSystem.Implementation

class DomConversionVisitor(DepthFirstVisitor):
	
	_result as SyntaxTree
	_currentType as TypeDeclaration
	_namespace as string
	
	def constructor(result as SyntaxTree):
		_result = result
		
	override def OnModule(node as Module):
		_namespace = null
		try:
			Visit(node.Namespace)
			Visit(node.Members)
		except e:
			MonoDevelop.Core.LoggingService.LogError ("Error in dom conversion", e)
			ex = e.InnerException
			while null != ex:
				MonoDevelop.Core.LoggingService.LogError (ex.StackTrace)
				ex = ex.InnerException
		
	override def OnNamespaceDeclaration(node as Boo.Lang.Compiler.Ast.NamespaceDeclaration):
		_namespace = node.Name
#		region = BodyRegionOf(node.ParentNode)
#		domUsing = UsingStatement ()
#		domUsing = DomUsing(IsFromNamespace: true, Region: region)
		astNamespace = ICSharpCode.NRefactory.CSharp.NamespaceDeclaration (Name: _namespace)
		LoggingService.LogError ("Found namespace {0}", _namespace)
		_result.AddChild (astNamespace, SyntaxTree.MemberRole)
		
	override def OnImport(node as Import):
		domUsing = UsingDeclaration (node.Namespace)
		_result.AddChild (domUsing, SyntaxTree.MemberRole)
		
	override def OnClassDefinition(node as ClassDefinition):
		OnTypeDefinition(node, ClassType.Class)
		
	override def OnInterfaceDefinition(node as InterfaceDefinition):
		OnTypeDefinition(node, ClassType.Interface)
		
	override def OnStructDefinition(node as StructDefinition):
		OnTypeDefinition(node, ClassType.Struct)
		
	override def OnEnumDefinition(node as EnumDefinition):
		OnTypeDefinition(node, ClassType.Enum)
		
	def OnTypeDefinition(node as TypeDefinition, classType as ClassType):
		LoggingService.LogError ("Found type {0}", node.FullName)
		converted = TypeDeclaration (
						Name: node.Name,
						ClassType: classType,
#						Location: LocationOf(node),
#						BodyRegion: BodyRegionOf(node),
#						DeclaringType: _currentType,
						Modifiers: ModifiersFrom(node)
					)
		
		WithCurrentType converted:
			Visit(node.Members)
					
		AddType(converted)
		
#	override def OnCallableDefinition(node as CallableDefinition):
#		parameters = System.Collections.Generic.List[of IParameter]()
#		for p in node.Parameters: parameters.Add(ParameterFrom(null, p))
#		
#		converted = DomType.CreateDelegate(_result, node.Name, LocationOf(node), ReturnTypeFrom(node.ReturnType), parameters)
#		converted.Modifiers = ModifiersFrom(node)
#		converted.DeclaringType = _currentType
#		converted.BodyRegion = BodyRegionOf(node)
#		
#		for p in parameters: p.DeclaringMember = converted
#		
#		AddType(converted)
		
	override def OnField(node as Field):
		if _currentType is null: return
		
		_currentType.AddChild(FieldDeclaration(
							Name: node.Name,
							ReturnType: ParameterTypeFrom(node.Type),
#							Location: LocationOf(node),
#							BodyRegion: BodyRegionOf(node),
#							DeclaringType: _currentType,
							Modifiers: ModifiersFrom(node)), SyntaxTree.MemberRole)
							
#	override def OnProperty(node as Property):
#		if _currentType is null: return
#		
#		try:
#			converted = DomProperty(
#								Name: node.Name,
#								ReturnType: ParameterTypeFrom(node.Type),
#								Location: LocationOf(node),
#								BodyRegion: BodyRegionOf(node),
#								DeclaringType: _currentType)
#			if node.Getter is not null:
#				converted.PropertyModifier |= PropertyModifier.HasGet
#				converted.GetterModifier = ModifiersFrom(node.Getter)
#				converted.GetRegion = BodyRegionOf(node.Getter)
#			if node.Setter is not null:
#				converted.PropertyModifier |= PropertyModifier.HasSet
#				converted.SetterModifier = ModifiersFrom(node.Setter)
#				converted.SetRegion = BodyRegionOf(node.Setter)
#								
#			_currentType.Add(converted)
#		except x:
#			print x, x.InnerException
#			
#	override def OnEvent(node as Event):
#		if _currentType is null: return
#		
#		converted = DomEvent(
#							Name: node.Name,
#							ReturnType: ParameterTypeFrom(node.Type),
#							Location: LocationOf(node),
#							BodyRegion: BodyRegionOf(node),
#							DeclaringType: _currentType)
#		_currentType.Add(converted)
#							
	override def OnEnumMember(node as EnumMember):
		if _currentType is null: return
		
		_currentType.AddChild (FieldDeclaration (
							Name: node.Name,
#							ReturnType: DomReturnType(_currentType),
#							Location: LocationOf(node),
#							DeclaringType: _currentType,
							Modifiers: Modifiers.Public | Modifiers.Static | Modifiers.Sealed), SyntaxTree.MemberRole)
							
	override def OnConstructor(node as Constructor):
		OnMethodImpl(node)
		
	override def OnDestructor(node as Destructor):
		OnMethodImpl(node)
		
	override def OnMethod(node as Method):
		OnMethodImpl(node)
		
	def OnMethodImpl(node as Method):
		if _currentType is null: return
		
		converted = MethodDeclaration (
							Name: node.Name,
#							Location: LocationOf(node),
#							BodyRegion: BodyRegionOf(node),
#							DeclaringType: _currentType,
							ReturnType: (MethodReturnTypeFrom(node) if IsRegularMethod(node.NodeType) else null),
							Modifiers: ModifiersFrom(node))
#							MethodModifier: methodModi			fier)
							
		for parameter in node.Parameters:
			converted.Parameters.Add(ParameterFrom(converted, parameter))
		
		_currentType.AddChild (converted, SyntaxTree.MemberRole)
		
	def IsRegularMethod(modifier as Boo.Lang.Compiler.Ast.NodeType):
		return true
		match modifier:
			case Boo.Lang.Compiler.Ast.NodeType.Constructor | Boo.Lang.Compiler.Ast.NodeType.Destructor:
				return false
			otherwise:
				return true
		
	def ModifiersFrom(node as TypeMember):
		modifiers = Modifiers.None
		modifiers |= Modifiers.Public if node.IsPublic
		modifiers |= Modifiers.Private if node.IsPrivate
		modifiers |= Modifiers.Protected if node.IsProtected
		modifiers |= Modifiers.Internal if node.IsInternal
		modifiers |= Modifiers.Static if node.IsStatic
		modifiers |= Modifiers.Virtual if node.IsVirtual
		modifiers |= Modifiers.Abstract if node.IsAbstract
		modifiers |= Modifiers.Override if node.IsOverride
		modifiers |= Modifiers.Sealed if node.IsFinal
		return modifiers
		
	def ParameterFrom(declaringMember as MethodDeclaration, parameter as Boo.Lang.Compiler.Ast.ParameterDeclaration):
		return ICSharpCode.NRefactory.CSharp.ParameterDeclaration (Type: ParameterTypeFrom (parameter.Type),
					Name: parameter.Name)
#					DeclaringMember: declaringMember, 
#					ReturnType: ParameterTypeFrom(parameter.Type),
#					Location: LocationOf(parameter))
					
	virtual def MethodReturnTypeFrom(method as Method):
		if method.ReturnType is not null:
			return ReturnTypeFrom(method.ReturnType)
		
		match ReturnTypeDetector().Detect(method):
			case ReturnTypeDetector.Result.Yields:
				return SimpleType ("System.Collections.IEnumerator")
			case ReturnTypeDetector.Result.Returns:
				return DefaultReturnType()
			otherwise:
				return AstType.Null
		
	class ReturnTypeDetector(DepthFirstVisitor):
		enum Result:
			Returns
			Yields
			None
			
		_result = Result.None
			
		def Detect(node as Method):
			VisitAllowingCancellation(node)
			return _result
			
		override def OnBlockExpression(node as BlockExpression):
			pass // skip over closures
		
		override def OnReturnStatement(node as Boo.Lang.Compiler.Ast.ReturnStatement):
			if node.Expression is null: return
			_result = Result.Returns
			
		override def OnYieldStatement(node as YieldStatement):
			_result = Result.Yields
			Cancel()
	
	virtual def ParameterTypeFrom(typeRef as TypeReference):
		if typeRef is null: return DefaultReturnType()
		return ReturnTypeFrom(typeRef)
		
	virtual def ReturnTypeFrom(typeRef as TypeReference):
		match typeRef:
			case SimpleTypeReference(Name: name):
				return SimpleType (name)
#			case ArrayTypeReference(ElementType: elementType):
#				type = ReturnTypeFrom(elementType)
#				type.ArrayDimensions = 1
#				type.SetDimension(0, 1)
#				return type
			otherwise:
				return AstType.Null
		
	def AddType(type as TypeDeclaration):
		if _currentType is not null:
			_currentType.AddChild (type, SyntaxTree.MemberRole)
		else:
#			type.Namespace = _namespace
			_result.AddChild (type, SyntaxTree.MemberRole)
		
	def WithCurrentType(type as TypeDeclaration, block as callable()):
		saved = _currentType
		_currentType = type
		try:
			block()
		ensure:
			_currentType = saved
			
	def BodyRegionOf(node as Node):
		startLocation = TextLocation (DomLocationFrom(node.LexicalInfo).Line, int.MaxValue)
		endLocation = TextLocation (DomLocationFrom(node.EndSourceLocation).Line, int.MaxValue)
#		# Start/end at the ends of lines
#		startLocation.Column = int.MaxValue
#		endLocation.Column = int.MaxValue
		return DomRegion(startLocation, endLocation)
		
	def LocationOf(node as Node):
		location = node.LexicalInfo
		return DomLocationFrom(location)
		
	def DomLocationFrom(location as SourceLocation):
		return TextLocation(location.Line, location.Column)
		
	def DefaultReturnType():
		return SimpleType ("object")
