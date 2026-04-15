import { writeFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import 'dotenv/config';

const BASE = process.env.SHORTCUT_BASE || 'http://cb-m1.taile1a732.ts.net:7777';
const TOKEN = process.env.AUTH_TOKEN;
if (!TOKEN) throw new Error('AUTH_TOKEN mangler i .env');

const AUTH = `Bearer ${TOKEN}`;

const escape = (s) =>
  String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');

const textField = (str) => `
        <dict>
          <key>Value</key>
          <dict>
            <key>string</key>
            <string>${escape(str)}</string>
          </dict>
          <key>WFSerializationType</key>
          <string>WFTextTokenString</string>
        </dict>`;

const variableTextField = (uuid, name) => `
        <dict>
          <key>Value</key>
          <dict>
            <key>attachmentsByRange</key>
            <dict>
              <key>{0, 1}</key>
              <dict>
                <key>OutputName</key>
                <string>${escape(name)}</string>
                <key>OutputUUID</key>
                <string>${uuid}</string>
                <key>Type</key>
                <string>ActionOutput</string>
              </dict>
            </dict>
            <key>string</key>
            <string>\uFFFC</string>
          </dict>
          <key>WFSerializationType</key>
          <string>WFTextTokenString</string>
        </dict>`;

const variableAttachment = (uuid, name) => `
        <dict>
          <key>Value</key>
          <dict>
            <key>OutputName</key>
            <string>${escape(name)}</string>
            <key>OutputUUID</key>
            <string>${uuid}</string>
            <key>Type</key>
            <string>ActionOutput</string>
          </dict>
          <key>WFSerializationType</key>
          <string>WFTextTokenAttachment</string>
        </dict>`;

const dictItem = (key, valueXml) => `
              <dict>
                <key>WFItemType</key>
                <integer>0</integer>
                <key>WFKey</key>${textField(key)}
                <key>WFValue</key>${valueXml}
              </dict>`;

const headersBlock = (entries) => `
        <key>WFHTTPHeaders</key>
        <dict>
          <key>Value</key>
          <dict>
            <key>WFDictionaryFieldValueItems</key>
            <array>${entries.map(([k, v]) => dictItem(k, v)).join('')}</array>
          </dict>
          <key>WFSerializationType</key>
          <string>WFDictionaryFieldValue</string>
        </dict>`;

const jsonBodyBlock = (entries) => `
        <key>WFHTTPBodyType</key>
        <string>JSON</string>
        <key>WFJSONValues</key>
        <dict>
          <key>Value</key>
          <dict>
            <key>WFDictionaryFieldValueItems</key>
            <array>${entries.map(([k, v]) => dictItem(k, v)).join('')}</array>
          </dict>
          <key>WFSerializationType</key>
          <string>WFDictionaryFieldValue</string>
        </dict>`;

const getURL = (uuid, url, headers) => `
    <dict>
      <key>WFWorkflowActionIdentifier</key>
      <string>is.workflow.actions.downloadurl</string>
      <key>WFWorkflowActionParameters</key>
      <dict>
        <key>UUID</key>
        <string>${uuid}</string>
        <key>WFURL</key>
        <string>${escape(url)}</string>
        <key>WFHTTPMethod</key>
        <string>GET</string>
        <key>ShowHeaders</key>
        <true/>${headersBlock(headers)}
      </dict>
    </dict>`;

const postURL = (uuid, url, headers, body) => `
    <dict>
      <key>WFWorkflowActionIdentifier</key>
      <string>is.workflow.actions.downloadurl</string>
      <key>WFWorkflowActionParameters</key>
      <dict>
        <key>UUID</key>
        <string>${uuid}</string>
        <key>WFURL</key>
        <string>${escape(url)}</string>
        <key>WFHTTPMethod</key>
        <string>POST</string>
        <key>ShowHeaders</key>
        <true/>${headersBlock(headers)}${jsonBodyBlock(body)}
      </dict>
    </dict>`;

const splitText = (uuid, sourceUuid, sourceName) => `
    <dict>
      <key>WFWorkflowActionIdentifier</key>
      <string>is.workflow.actions.text.split</string>
      <key>WFWorkflowActionParameters</key>
      <dict>
        <key>UUID</key>
        <string>${uuid}</string>
        <key>WFTextSeparator</key>
        <string>New Lines</string>
        <key>text</key>${variableTextField(sourceUuid, sourceName)}
      </dict>
    </dict>`;

const chooseFromList = (uuid, sourceUuid, sourceName, prompt) => `
    <dict>
      <key>WFWorkflowActionIdentifier</key>
      <string>is.workflow.actions.choosefromlist</string>
      <key>WFWorkflowActionParameters</key>
      <dict>
        <key>UUID</key>
        <string>${uuid}</string>
        <key>WFChooseFromListActionPrompt</key>${textField(prompt)}
        <key>WFInput</key>${variableAttachment(sourceUuid, sourceName)}
      </dict>
    </dict>`;

const dictate = (uuid) => `
    <dict>
      <key>WFWorkflowActionIdentifier</key>
      <string>is.workflow.actions.dictatetext</string>
      <key>WFWorkflowActionParameters</key>
      <dict>
        <key>UUID</key>
        <string>${uuid}</string>
        <key>WFSpeechLanguage</key>
        <string>da-DK</string>
        <key>WFDictateTextStopListening</key>
        <string>After Tap</string>
        <key>CustomOutputName</key>
        <string>Dikteret tekst</string>
      </dict>
    </dict>`;

const wrapPlist = (actions) => `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>WFWorkflowActions</key>
  <array>${actions.join('')}
  </array>
  <key>WFWorkflowClientVersion</key>
  <string>2607.1.2</string>
  <key>WFWorkflowMinimumClientVersion</key>
  <integer>900</integer>
  <key>WFWorkflowMinimumClientVersionString</key>
  <string>900</string>
  <key>WFWorkflowIcon</key>
  <dict>
    <key>WFWorkflowIconStartColor</key>
    <integer>2071128575</integer>
    <key>WFWorkflowIconGlyphNumber</key>
    <integer>59446</integer>
  </dict>
  <key>WFWorkflowImportQuestions</key>
  <array/>
  <key>WFWorkflowInputContentItemClasses</key>
  <array/>
  <key>WFWorkflowHasOutputFallback</key>
  <false/>
  <key>WFWorkflowHasShortcutInputVariables</key>
  <false/>
  <key>WFWorkflowTypes</key>
  <array>
    <string>NCWidget</string>
    <string>WatchKit</string>
  </array>
</dict>
</plist>
`;

// ── Shortcut 1: "Tal til cc" — daily use, no picker ────────────────────
{
  const ID_DICTATE = randomUUID();
  const ID_POST = randomUUID();
  const actions = [
    dictate(ID_DICTATE),
    postURL(
      ID_POST,
      BASE + '/speak',
      [['Authorization', textField(AUTH)], ['Content-Type', textField('application/json')]],
      [['text', variableTextField(ID_DICTATE, 'Dikteret tekst')]],
    ),
  ];
  writeFileSync('tal-til-cc.shortcut', wrapPlist(actions));
  console.log('Wrote tal-til-cc.shortcut');
}

// ── Shortcut 2: "Vælg cc-mål" — picker, sets sticky target ─────────────
{
  const ID_LIST = randomUUID();
  const ID_SPLIT = randomUUID();
  const ID_CHOOSE = randomUUID();
  const ID_POST = randomUUID();
  const actions = [
    getURL(ID_LIST, BASE + '/sessions.txt', [['Authorization', textField(AUTH)]]),
    splitText(ID_SPLIT, ID_LIST, 'Indhold af URL'),
    chooseFromList(ID_CHOOSE, ID_SPLIT, 'Splittet tekst', 'Vælg cc-session'),
    postURL(
      ID_POST,
      BASE + '/target',
      [['Authorization', textField(AUTH)], ['Content-Type', textField('application/json')]],
      [['target', variableTextField(ID_CHOOSE, 'Valgt punkt')]],
    ),
  ];
  writeFileSync('vaelg-cc-maal.shortcut', wrapPlist(actions));
  console.log('Wrote vaelg-cc-maal.shortcut');
}
