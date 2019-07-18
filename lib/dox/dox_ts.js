"use strict";
// tslint:disable:no-bitwise
Object.defineProperty(exports, "__esModule", { value: true });
const ts = require("typescript");
function getTags(jsDoc) {
    if (!jsDoc) {
        return [];
    }
    const tags = jsDoc.tags;
    if (!tags) {
        return [];
    }
    return tags.map((tag) => {
        if (ts.isJSDocParameterTag(tag)) {
            const type = 'param';
            const name = tag.name.text;
            const description = tag.comment;
            const string = `${name} ${tag.comment}`;
            return { type, string, name, description, types: [], optional: false };
        }
        else if (ts.isJSDocReturnTag(tag)) {
            const type = 'return';
            const description = tag.comment;
            const string = tag.comment;
            return { type, string, description, types: [], optional: false };
        }
        else {
            const type = tag.tagName.text.toLowerCase();
            if (type === 'memberof') {
                const parent = tag.comment;
                const string = tag.comment;
                return { type, parent, string };
            }
            else {
                const string = tag.comment;
                return { type, string };
            }
        }
    });
}
function traverse(sourceFile, node, comments, parentContext) {
    const jsDocs = node.jsDoc;
    const jsDoc = jsDocs && jsDocs.length > 0 && jsDocs[jsDocs.length - 1];
    let startPos;
    if (jsDoc) {
        startPos = jsDoc.pos;
    }
    else {
        startPos = node.pos;
    }
    let codeStartPos;
    if (jsDoc) {
        codeStartPos = jsDoc.end + 1;
    }
    else {
        codeStartPos = node.pos;
    }
    const line = ts.getLineAndCharacterOfPosition(sourceFile, startPos).line + 1;
    const codeStart = ts.getLineAndCharacterOfPosition(sourceFile, codeStartPos).line + 1;
    const description = { full: '', summary: '', body: '' };
    if (jsDoc) {
        description.full = jsDoc.comment || '';
        description.summary = description.full.split('\n\n')[0];
        description.body = description.full.split('\n\n').slice(1).join('\n\n');
    }
    if (jsDocs && jsDocs.length > 1) {
        for (const doc of jsDocs.slice(0, jsDocs.length - 1)) {
            const comment = {
                code: '', codeStart: 1, ctx: undefined, description: { full: '', summary: '', body: '' },
                isClass: false, isConstructor: false, isEvent: false, isPrivate: false,
                line: 1, tags: getTags(doc),
            };
            comments.push(comment);
        }
    }
    if (ts.isSourceFile(node)) {
        for (const statement of node.statements) {
            traverse(sourceFile, statement, comments, parentContext);
        }
    }
    else if (ts.isClassDeclaration(node)) {
        const name = sourceFile.text.substring(node.name.pos, node.name.end).trim();
        const ctx = {
            cons: name,
            constructor: name,
            extends: '',
            name,
            string: `new ${name}()`,
            type: 'class',
        };
        const comment = {
            code: node.getText(sourceFile), codeStart, ctx, description,
            isClass: true, isConstructor: false, isEvent: false, isPrivate: false,
            line, tags: getTags(jsDoc),
        };
        comments.push(comment);
        for (const member of node.members) {
            traverse(sourceFile, member, comments, comment.ctx);
        }
    }
    else if (ts.isConstructorDeclaration(node)) {
        const ctx = {
            cons: parentContext.name,
            constructor: parentContext.name,
            is_constructor: true,
            name: 'constructor',
            string: `${parentContext.name}.prototype.constructor()`,
            type: 'method',
        };
        const comment = {
            code: node.getText(sourceFile), codeStart, ctx, description,
            isClass: false, isConstructor: false, isEvent: false, isPrivate: false,
            line, tags: getTags(jsDoc),
        };
        comments.push(comment);
    }
    else if (ts.isMethodDeclaration(node) || ts.isMethodSignature(node)) {
        const name = sourceFile.text.substring(Math.max(codeStartPos, node.name.pos), node.name.end).trim();
        const modifierFlags = ts.getCombinedModifierFlags(node);
        const isPrivate = (modifierFlags & (ts.ModifierFlags.Private | ts.ModifierFlags.Protected)) !== 0;
        const isStatic = (modifierFlags & ts.ModifierFlags.Static) !== 0;
        let ctx;
        if (isStatic) {
            ctx = {
                name,
                receiver: parentContext.name,
                string: `${parentContext.name}.${name}()`,
                type: 'method',
            };
        }
        else {
            ctx = {
                cons: parentContext.name,
                constructor: parentContext.name,
                name,
                string: `${parentContext.name}.prototype.${name}()`,
                type: 'method',
            };
        }
        const comment = {
            code: node.getText(sourceFile), codeStart, ctx, description,
            isClass: false, isConstructor: false, isEvent: false, isPrivate,
            line, tags: getTags(jsDoc),
        };
        comments.push(comment);
    }
    else if (ts.isPropertyDeclaration(node) || ts.isPropertySignature(node)) {
        const name = sourceFile.text.substring(Math.max(codeStartPos, node.name.pos), node.name.end).trim();
        const modifierFlags = ts.getCombinedModifierFlags(node);
        const isPrivate = (modifierFlags & (ts.ModifierFlags.Private | ts.ModifierFlags.Protected)) !== 0;
        const isStatic = (modifierFlags & ts.ModifierFlags.Static) !== 0;
        let ctx;
        if (isStatic) {
            ctx = {
                name,
                receiver: parentContext.name,
                string: `${parentContext.name}.${name}()`,
                type: 'property',
            };
        }
        else {
            ctx = {
                cons: parentContext.name,
                constructor: parentContext.name,
                name,
                string: `${parentContext.name}.prototype.${name}()`,
                type: 'property',
            };
        }
        const comment = {
            code: node.getText(sourceFile), codeStart, ctx, description,
            isClass: false, isConstructor: false, isEvent: false, isPrivate,
            line, tags: getTags(jsDoc),
        };
        comments.push(comment);
    }
    else if (ts.isFunctionDeclaration(node)) {
        const name = sourceFile.text.substring(node.name.pos, node.name.end).trim();
        const ctx = {
            name,
            string: `${name}()`,
            type: 'function',
        };
        const comment = {
            code: node.getText(sourceFile), codeStart, ctx, description,
            isClass: false, isConstructor: false, isEvent: false, isPrivate: false,
            line, tags: getTags(jsDoc),
        };
        comments.push(comment);
    }
    else if (ts.isExpressionStatement(node)) {
        const expression = node.expression;
        let ctx;
        if (ts.isBinaryExpression(expression)) {
            const isFunc = ts.isFunctionExpression(expression.right);
            const left = expression.left;
            if (ts.isPropertyAccessExpression(left)) {
                if (ts.isIdentifier(left.expression)) {
                    ctx = {
                        name: left.name.text,
                        receiver: left.expression.text,
                        string: `${left.expression.text}.${left.name.text}()`,
                        type: isFunc ? 'method' : 'property',
                    };
                }
                else if (ts.isPropertyAccessExpression(left.expression)) {
                    const leftExpr = left.expression;
                    if (leftExpr.name.text === 'prototype' && ts.isIdentifier(leftExpr.expression)) {
                        ctx = {
                            cons: leftExpr.expression.text,
                            constructor: leftExpr.expression.text,
                            name: left.name.text,
                            string: `${leftExpr.expression.text}.prototype.${left.name.text}()`,
                            type: isFunc ? 'method' : 'property',
                        };
                    }
                }
            }
        }
        if (ctx) {
            const comment = {
                code: node.getText(sourceFile), codeStart, ctx, description,
                isClass: false, isConstructor: false, isEvent: false, isPrivate: false,
                line, tags: getTags(jsDoc),
            };
            comments.push(comment);
        }
    }
    else if (ts.isInterfaceDeclaration(node)) {
        const name = sourceFile.text.substring(node.name.pos, node.name.end).trim();
        const ctx = {
            cons: name,
            constructor: name,
            extends: '',
            name,
            string: `new ${name}()`,
            type: 'class',
        };
        const comment = {
            class_code: node.getText(sourceFile), class_codeStart: codeStart, ctx, description,
            isClass: true, isConstructor: false, isEvent: false, isPrivate: false, isStatic: true,
            line, tags: getTags(jsDoc),
        };
        comments.push(comment);
        for (const member of node.members) {
            traverse(sourceFile, member, comments, comment.ctx);
        }
    }
}
function parseCommentsTS(data) {
    const comments = [];
    const compilerOptions = { strict: true, target: ts.ScriptTarget.ES2017 };
    const compilerHost = ts.createCompilerHost(compilerOptions, true);
    compilerHost.getSourceFile = (filename, languageVersion) => {
        const text = filename === 'source.ts' ? data : ts.sys.readFile(filename);
        return ts.createSourceFile(filename, text, languageVersion);
    };
    const program = ts.createProgram(['source.ts'], compilerOptions, compilerHost);
    const sourceFile = program.getSourceFile('source.ts');
    traverse(sourceFile, sourceFile, comments, null);
    return comments;
}
exports.parseCommentsTS = parseCommentsTS;
